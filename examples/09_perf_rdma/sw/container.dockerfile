FROM srcinc-docker.artifactory.srcinc.com/ubi9/ubi:9.6 AS builder

WORKDIR /root

# setup src mirror repos
RUN dnf config-manager --disable '*' && \
    echo "[mirror-baseos]" > /etc/yum.repos.d/src-mirrors.repo && \
    echo "baseurl=https://mirrors.srcinc.com/repo/stable/redhat/9/rhel-9-for-x86_64-baseos-rpms/" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "name=mirror-baseos" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "priority=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "[mirror-appstream]" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "baseurl=https://mirrors.srcinc.com/repo/stable/redhat/9/rhel-9-for-x86_64-appstream-rpms/" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "name=mirror-appstream" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "priority=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "[mirror-epel]" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "baseurl=https://mirrors.srcinc.com/repo/stable/epel/9/Everything/x86_64/" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "name=mirror-epel" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/src-mirrors.repo  && \
    echo "priority=1" >> /etc/yum.repos.d/src-mirrors.repo


    # install dev tools for build
RUN dnf install -y rdma-core \
	gcc-c++ \
        make \
        cmake \
        boost-devel \
     && dnf clean all

COPY . .
	
RUN mkdir -p build_sw/09_perf_rdma/client && cd build_sw/09_perf_rdma/client && \
    cmake ../../../examples/09_perf_rdma/sw/ -DINSTANCE=client && \
    make

RUN mkdir -p build_sw/09_perf_rdma/server && cd build_sw/09_perf_rdma/server && \
    cmake ../../../examples/09_perf_rdma/sw/ -DINSTANCE=server && \
    make


FROM srcinc-docker.artifactory.srcinc.com/ubi9/ubi:9.6

RUN dnf config-manager --disable '*' && \
    echo "[mirror-baseos]" > /etc/yum.repos.d/src-mirrors.repo && \
    echo "baseurl=https://mirrors.srcinc.com/repo/stable/redhat/9/rhel-9-for-x86_64-baseos-rpms/" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "name=mirror-baseos" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "priority=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "[mirror-appstream]" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "baseurl=https://mirrors.srcinc.com/repo/stable/redhat/9/rhel-9-for-x86_64-appstream-rpms/" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "name=mirror-appstream" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "priority=1" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "[mirror-epel]" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "baseurl=https://mirrors.srcinc.com/repo/stable/epel/9/Everything/x86_64/" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "name=mirror-epel" >> /etc/yum.repos.d/src-mirrors.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/src-mirrors.repo  && \
    echo "priority=1" >> /etc/yum.repos.d/src-mirrors.repo

RUN dnf install -y \
    libstdc++ \
    boost \
    && dnf clean all

WORKDIR /app
COPY --from=builder /root/build_sw/09_perf_rdma/server ./server
COPY --from=builder /root/build_sw/09_perf_rdma/client ./client


ENV LD_LIBRARY_PATH=/app/client/coyote:/app/server/coyote:$LD_LIBRARY_PATH

ENTRYPOINT ["/bin/bash"]


