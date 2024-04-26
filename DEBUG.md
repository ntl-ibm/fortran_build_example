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
* backoffLimit  (default is 6)

The backoffLimit tells the JOB to create a new pod and try again up to 6 times when the pod fails. (You’ll get 7 failures).  

The time between retries is exponentially increased up to six minutes.

* restartPolicy (set to Never in the example)

The restartPolicy never tells OpenShift to not restart the container when it fails.  The Pod will end up in an error state (as opposed to restarting the container and incrementing the restart count).

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
OpenShift runs containers under an arbitrary user id.  For files and directories to be accessed, they must be owned by the root group and be read/writtable by that group.  More information is available [here](https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html#use-uid_create-images)

