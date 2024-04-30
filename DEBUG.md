# Debug commands associated with README.md

There are times where an interactive shell inside of a container can be very helpful for debug.

## Start a container in a new pod with interactive shell.

```shell
oc run example-pod --image image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0 -it --rm -- bash
```

- “example-pod” is the name of the pod
- --image is the container image that you want to run
- -it gives you an Interactive Terminal
- --rm removes the pod after you exit the shell
- -- (followed by space) means everything after that is the command…in this case it starts a bash shell.

## Start an interactive shell within a container of a running job

If you already have the pod you are interested in debugging, then you can do the same kind of thing with oc exec.
Frist get the name of the pod (assuming that the pod is running as part of a job).

```
oc get pods -l job-name=fortran-example-job
```

 <PRE>
NAME                        READY   STATUS    RESTARTS   AGE
fortran-example-job-ftxt8   1/1     Running   0          12s
 </PRE>

And then open a bash shell in the container

```
oc exec fortran-example-job-ftxt8 -it -- bash
```

The catch with doing that is as soon as the command that started the container ends, the container ends and your interactive session gets terminated.

## Debug a failing job

There are two important parts to the job spec:

- backoffLimit (default is 6)

The backoffLimit tells the JOB to create a new pod and try again up to 6 times when the pod fails. (You’ll get 7 failures).

The time between retries is exponentially increased up to six minutes.

- restartPolicy (set to Never in the example)

The restartPolicy never tells OpenShift to not restart the container when it fails. The Pod will end up in an error state (as opposed to restarting the container and incrementing the restart count).

After failing more times than the backoffLimit, the job is marked "Failed" with reason "BackoffLimitExceeded".

If a describe is done on a pod that has failed, you will be able to see the exit code for a container that has failed.

```yaml
Containers:
  main:
    Container ID:  xxxx
    Image:         image-registry.openshift-image-registry.svc:5000/xxxx
    Image ID:      image-registry.openshift-image-registry.svc:5000/xxxx
    Port:          <none>
    Host Port:     <none>
    Command:
      ./Application
    State:          Terminated
      Reason:       Error
      Exit Code:    2
      Started:      Thu, 25 Apr 2024 08:50:41 -0400
      Finished:     Thu, 25 Apr 2024 08:50:41 -0400
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
```

The logs for the job can be obtained using the `oc logs -n <namespace> <pod> -c <container-name> -f` command.

## Missing files or permission problems (for files that should be included by a continaer image build).

OpenShift runs containers under an arbitrary user id. For files and directories to be accessed, they must be owned by the root group and be read/writtable by that group. More information is available [here](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images)

## Caching of container images

Container images are stored in a cache on each node for use by a container. Images are pulled into the cache depending on the "ImagePullPolicy" of the container spec.

The K8S documentation can be found [here](https://kubernetes.io/docs/concepts/containers/images/#updating-images).

The following job description shows how to set the image pull pollicy to always pull the newest version of the image image.

```yaml
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
          #### Set ImagePullPolicy
          imagePullPolicy: Always
          image: image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0
          command: ["./Application", "5"]
      restartPolicy: Never
```

### Alternatives

These alternatives can be used when the imagePullPolicy is not specified (the default pull policy)

- Tag the image with "latest". The default for latest is to use an image pull policy of "Always".
- Use a specific digest for the image

### Debug

The digest can be used to verify that the container image that has been built is the actual image that the container is running with.

#### Digest of image pushed to the container repository

The build logs, you can see the digest of the image that was successfuly pushed. (Make sure that you are looking at the most recent build!)

```
oc logs build.build.openshift.io/binary-single-step-4 -f
```

Digest is: 547761cbb4104164419e2e8d1e8062b0b4c6f2d05a387b71563b18fd6fbad30f

<PRE>
[2/2] COMMIT temp.builder.openshift.io/ntl-us-ibm-com/binary-single-step-4:0699c6d7
--> 8c2090f13d4
Successfully tagged temp.builder.openshift.io/ntl-us-ibm-com/binary-single-step-4:0699c6d7
8c2090f13d4cd95c9989dd2090ec6c4be4fd2bd87406f1600e1ac0a2aecfe721

Pushing image image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0 ...
Getting image source signatures
Copying blob sha256:5f70bf18a086007016e948b04aed3b82103a36bea41755b6cddfaf10ace3c6ef
Copying blob sha256:d7558242f779abccfc5b2ea4dd08a7e096aeea649c6161d91e7a0dd54efc6c54
Copying blob sha256:323091aa01e7e3274a9b2df24aaf0620d929b2781b468576b237125c22ab88ba
Copying blob sha256:3c5f4197179c94b194e535b2b1340f1de133ccf8155162e44cb3a7ad3f639ff5
Copying config sha256:8c2090f13d4cd95c9989dd2090ec6c4be4fd2bd87406f1600e1ac0a2aecfe721
Writing manifest to image destination
Storing signatures
Successfully pushed image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image@sha256:547761cbb4104164419e2e8d1e8062b0b4c6f2d05a387b71563b18fd6fbad30f
Push successful
</PRE>

#### Images in the image stream

Available versions of images are tracked in the image stream; image stream tags are created each time an image is built. You can see the images and digests with the following command:

```
oc get istag
```

The output might look something like this:

```
NAME                         IMAGE REFERENCE    UPDATED
my-container-image:1.0.0     <digest here>      12 minutes ago
```

The image reference should match the reference pushed to the registry by the build.

#### Image used by the container

The first step is to find the pod of interest, pods that were created by a job have a label with the job name.

```
]$ oc get pods -l job-name=fortran-example-job
NAME                        READY   STATUS      RESTARTS   AGE
fortran-example-job-6f52d   0/1     Completed   0          33m
```

It is then possible to do a describe on the pod.

```
]$ oc describe pod fortran-example-job-pk2x8
Name:             fortran-example-job-pk2x8
Namespace:        ntl-us-ibm-com
Priority:         0
Service Account:  default
Node:             arl-ocp2-wrk-ac922-1.openshift.ibmscoutsandbox/10.3.177.201
Start Time:       Tue, 30 Apr 2024 10:54:48 -0500
Labels:           controller-uid=943e287b-138a-4a0a-adbb-77e74eb03396
                  job-name=fortran-example-job
Annotations:      k8s.v1.cni.cncf.io/network-status:
                    [{
                        "name": "openshift-sdn",
                        "interface": "eth0",
                        "ips": [
                            "10.254.4.107"
                        ],
                        "default": true,
                        "dns": {}
                    }]
                  k8s.v1.cni.cncf.io/networks-status:
                    [{
                        "name": "openshift-sdn",
                        "interface": "eth0",
                        "ips": [
                            "10.254.4.107"
                        ],
                        "default": true,
                        "dns": {}
                    }]
                  kubernetes.io/limit-ranger: LimitRanger plugin set: cpu, memory request for container main
                  openshift.io/scc: restricted-v2
                  seccomp.security.alpha.kubernetes.io/pod: runtime/default
                  sidecar.istio.io/inject: false
Status:           Succeeded
IP:               10.254.4.107
IPs:
  IP:           10.254.4.107
Controlled By:  Job/fortran-example-job
Containers:
  main:
    Container ID:  cri-o://7907be6d4648ca3cc4e9c323249e363c8235bfba20cb4d99488eadf2a95ae5f7
    Image:         image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0
    Image ID:      image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image@sha256:fcbe27d9dcebee568a1d950de38617d10118c708abd228164ab3231c07700a09
    Port:          <none>
    Host Port:     <none>
    Command:
      ./Application
      5
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 30 Apr 2024 10:54:50 -0500
      Finished:     Tue, 30 Apr 2024 10:54:56 -0500
    Ready:          False
    Restart Count:  0
    Requests:
      cpu:        200m
      memory:     100Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-qn7xv (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      True
Volumes:
  kube-api-access-qn7xv:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
    ConfigMapName:           openshift-service-ca.crt
    ConfigMapOptional:       <nil>
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/memory-pressure:NoSchedule op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason          Age   From               Message
  ----    ------          ----  ----               -------
  Normal  Scheduled       19s   default-scheduler  Successfully assigned ntl-us-ibm-com/fortran-example-job-pk2x8 to arl-ocp2-wrk-ac922-1.openshift.ibmscoutsandbox
  Normal  AddedInterface  17s   multus             Add eth0 [10.254.4.107/24] from openshift-sdn
  Normal  Pulled          17s   kubelet            Container image "image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0" already present on machine
  Normal  Created         17s   kubelet            Created container main
  Normal  Started         16s   kubelet            Started container main
```

The **Image ID** has the digest for the image that the container was running with. In the **Events** section, we can see that the image was already present and not pulled.

If the image was pulled from an image registry, the event might look something like this:

```
Events:
  Type    Reason          Age   From               Message
  ----    ------          ----  ----               -------
  Normal  Scheduled       9s    default-scheduler  Successfully assigned ntl-us-ibm-com/fortran-example-job-8vrlf to arl-ocp2-wrk-ac922-1.openshift.ibmscoutsandbox
  Normal  AddedInterface  8s    multus             Add eth0 [10.254.4.108/24] from openshift-sdn
  Normal  Pulling         8s    kubelet            Pulling image "image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0"
  Normal  Pulled          6s    kubelet            Successfully pulled image "image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0" in 1.501141631s (1.501151352s including waiting)
```

If the image id does not match the most recent image id, then the cache on the machine may have an older version of the image. The container start-up can be forced to pull the image by modifying the pull policy, specifying a digest, or updating the tag.
