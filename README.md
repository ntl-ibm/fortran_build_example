# Example of building a Fortran application with OpenShift

This repo contains

1. A 'src' directory of Fortran parts.
1. A Dockerfile for building the container image.
1. This readme, with the command line steps required to build and test the image.

## Clone this repo

The source code (including the Dockerfile) needs to be copied to a local directory where `oc` commands can be run.

```shell
git clone https://github.com/ntl-ibm/fortran_build_example.git
```

Another option would be to download and uncompress the zip file.

## Set the default project

My namespace is ntl-us-ibm-com, so that is what is used in the examples.

```bash
oc project ntl-us-ibm-com
```

## Create the build configuration

Create a yaml for the build config. (You can run the following command in bash)

In the yaml:

1.  The config is named "binary-single-step".

1.  The source type is Binary.

    Binary means that the source will come from local storage, rather than github or gitlab.

1.  The strategy is Docker.

    This means the source directory will have a Dockerfile, which will be used for the build.

1.  The output will be an image.

    a. The image is stored in the local registry

    b. The repository is [current-project] / "my-container-image".

    c. The tag will be 1.0.0


Note: The current project is set into the yaml file by the bash snipplet's cat command with variable replacement.
  
The command redirects to file and uses a [heredoc](https://linuxize.com/post/bash-heredoc/).

```
cat << EOF > buildcfg.yaml
---
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: binary-single-step
spec:
  source:
    type: Binary
  strategy:
    type: Docker
  output:
    to:
      kind: DockerImage
      name: image-registry.openshift-image-registry.svc:5000/$(oc project --short)/my-container-image:1.0.0
EOF
```

### Use the oc command to create the build config in openshift.

`oc create -f ./buildcfg.yaml`

You should see a message similar to:

> buildconfig.build.openshift.io/binary-single-step created

Tip: The resources created from the yaml can be deleted by:
`oc delete -f ./buildcfg.yaml`

## Start a build

It is now possible to trigger a build from the command line. For this example, the source code (with the Docker file) is in the directory ./fortran_build_example.

```
oc start-build buildconfig.build.openshift.io/binary-single-step --from-dir ./fortran_build_example
```

You should expect to see messages like this:

> Uploading directory "fortran_build_example" as binary input for the build ...<br/>
> .. <br>
> Uploading finished <br>
> build.build.openshift.io/binary-single-step-2 started <br>

The last line contains the build resource: build.build.openshift.io/binary-single-step-2

**The build resource will be different each time a build is started for the config.**

We'll use the build resource to monitor the build.

## Monitor the build

Using the build resource, you can retrieve the logs of the build. The "-f" will cause the logs to be streamed until the build completes.

`oc logs build.build.openshift.io/binary-single-step-2 -f`

You can get the overall status of the build by doing a describe.

`oc describe build.build.openshift.io/binary-single-step-2`

## Use the container image in a Job

In the build logs, you'll see a couple of lines (assuming a successful build).

> Pushing image image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image:1.0.0 ...

This is where to access the image, with a nice tag name (1.0.0). This name was set in the build config. The tag is not 'absolute', a future build could create a new image with the same tag.

> Successfully pushed image-registry.openshift-image-registry.svc:5000/ntl-us-ibm-com/my-container-image@sha256:858acd2399adc68ae30c9db53fdc84cd4eac62c9ef23dd45e16e73149d6dd31a

This is the absolute digest for the image. It will never be reused and will always refer to this image. Either name can be used when referring to the image.

For test purposes, we can create a Job that contains a Pod with a container using the image.
The command has been overriden in this example to provide a parameter on the command line. If we did not supply the command, then the default command from the Docker file would be used.

```
cat << EOF > my-job.yaml
---
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
          image: image-registry.openshift-image-registry.svc:5000/$(oc project --short)/my-container-image:1.0.0
          command: ["./Application", "5"]
      restartPolicy: Never
EOF
```

Create the job
`oc create -f my-job.yaml`

You should see output such as:

> job.batch/fortran-example-job created

You can monitor the job's progress with:
`oc get job.batch/fortran-example-job  --watch`

You should eventually see something like:

<PRE>
NAME                COMPLETIONS DURATION AGE
fortran-example-job   0/1           8s         8s
fortran-example-job   0/1           10s        10s
fortran-example-job   0/1           15s        15s
fortran-example-job   0/1           17s        17s
fortran-example-job   1/1           17s        17s
</PRE>

(Press CTRL-C to break out of the watch at this point)

You can get the logs for the completed job by:
`oc logs -l job-name=fortran-example-job`

You can delete the job with either:
`oc delete -f my-job.yaml`

or

`oc delete job.batch/fortran-example-job`

(The shorter version of `oc delete job fortran-example-job` is also fine.)
