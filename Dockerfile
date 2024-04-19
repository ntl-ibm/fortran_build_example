FROM ubi8/ubi:8.9-1160 AS build
LABEL maintainer="Nick Lawrence <ntl@us.ibm.com>"
RUN dnf -y install gcc-gfortran \
    && dnf clean all \
    && rm -rf /var/cache/dnf/* \
    && rm -rf /var/cache/yum 

WORKDIR /build
COPY ./src/* .
RUN gfortran -c *.f90 \
    && gfortran *.o -o Application


FROM ubi8/ubi:8.9-1160
LABEL maintainer="Nick Lawrence <ntl@us.ibm.com>"
WORKDIR /app
COPY --from=build /build/Application .
RUN chgrp 0 Application

USER 1000
CMD ["/app/Application"]
