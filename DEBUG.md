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

