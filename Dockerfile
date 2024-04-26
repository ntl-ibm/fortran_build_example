# Copyright 2024 IBM All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###
# Dockerfile creation tips: 
# https://docs.openshift.com/container-platform/4.12/openshift_images/create-images.html
###

#################################################
# This is the "build" stage of the Docker build
# We can copy files from this stage into the
# application image (which will be the next stage)
#################################################
# UBI Image Doc: https://catalog.redhat.com/software/containers/ubi8/ubi/5c359854d70cc534b3a3784e?architecture=ppc64le&image=660382bfd810c7615d566e00&container-tabs=packages
FROM ubi8/ubi:8.9-1160 AS build

# Install Fortran compiler
RUN dnf -y install gcc-gfortran

# Copy source to build directory and Compile
WORKDIR /build
COPY ./src/* .
RUN gfortran -c *.f90 \
    && gfortran *.o -o Application


#######################################################
# This builds the container image with the application
#######################################################
# UBI Image Doc: https://catalog.redhat.com/software/containers/ubi8/ubi/5c359854d70cc534b3a3784e?architecture=ppc64le&image=660382bfd810c7615d566e00&container-tabs=packages
FROM ubi8/ubi:8.9-1160
LABEL maintainer="Nick Lawrence <ntl@us.ibm.com>"

# Install Fortran runtime (and cleanup cache afterwards)
RUN dnf -y install libgfortran \
    && dnf clean all \
    && rm -rf /var/cache/dnf/* \
    && rm -rf /var/cache/yum

# Copy the application from the build stage to /app directory
WORKDIR /app
COPY --from=build /build/Application .

# OpenShift will run the container under random user id, and that id is 
# member of the root group. Make sure application is onwed by root group so it
# can run as part of the container.
RUN chgrp 0 Application

# Normal K8S doesn't run under a random user id. For security, we never want
# the container to run as root.
USER 1000:0

# Default command to run when the container is started
CMD ["/app/Application"]
