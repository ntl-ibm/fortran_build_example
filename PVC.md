# Extend the example to use PVCs

This document describes adjustment to README.md so that the output of the job is stored on a PVC.

## Create a PVC with access mode "Read Write Many"

This is a Yaml document to create a PVC that multiple pods can use it at the same time.

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-for-fortran-results
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
```

It is also possible to the PVC in the Kubeflow central dashboard; the “Volumes” panel has a “new volume” button.

Either way the key is that it must be “ReadWriteMany”.

## Modify the Job Description to use the PVC

The job description from README.md can be modified like this:
```
apiVersion: batch/v1
kind: Job
metadata:
  name: fortran-example-job
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      containers:
        - name: main
          image: image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0
          command:
            - /bin/sh
            - -c
            - |
              rm -rf /mnt/pvc-for-fortran-results/${JOB_NAME} || true
              mkdir /mnt/pvc-for-fortran-results/${JOB_NAME}
              ./Application 5 > /mnt/pvc-for-fortran-results/${JOB_NAME}/application.std.out
          volumeMounts:
            - mountPath: /mnt/pvc-for-fortran-results
              name: pvc-for-fortran-results
          env:
            - name: JOB_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['job-name']
      volumes:
        - name: pvc-for-fortran-results
          persistentVolumeClaim:
            claimName: pvc-for-fortran-results
 
      restartPolicy: Never
```


The spec now has a “volumes” key, and the pvc has been added to this list of volumes that the containers can mount. 
The “main” container now has a volumeMounts key.  The single element in this list has the name of the volume (matches the volumes section of the spec) and the path to mount that volume in the container.
 
That’s enough to make the PVC storage available to the container. But when using Katib, there will be many jobs running, probably at the same time. We would like to be able to keep the produced files distinct and map them back to the job that created them for later review.  I provide the job name as an environment variable, and then I can store output materials in a directory named after the job.
 
The “env” section defines the environment variables that will be available to the container.  The valueFrom is a fancy way to the get the job name set into the JOB_NAME environment variable.
 
In practice, users probably want a script or program in your container to be the command…I just did an inline script for easier visualization.
1.       Delete the output directory, if it exists
2.       Create the output directory.
3.       For demo, write contents of my hello world application to a file in the directory for the job.

## View the data using Kubeflow Notebook
One approach to accessing the data from the job is to start a Kubeflow Notebook server with the volume mounted.

1. Create new notebook, and under “Data Volumes”, “Attach existing volume”.  Choose the volume from the drop-down menu.
2. Launch the notebook server
3. Connect to the notebook server
4. The directory tree will appear in the file explorer, this tree will have a path into the PVC.
5. The terminal inside the notebook server can be used to tar an entire directory tree for download. (If the data needs to be downloaded for backup or analysis).


