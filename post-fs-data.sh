#!/system/bin/sh

exec > /data/local/tmp/UniversalCACert.log
exec 2>&1

set -x

MODDIR=${0%/*}

set_context() {
    [ "$(getenforce)" = "Enforcing" ] || return 0

    default_selinux_context=u:object_r:system_file:s0
    selinux_context=$(ls -Zd $1 | awk '{print $1}')

    if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
        chcon -R $selinux_context $2
    else
        chcon -R $default_selinux_context $2
    fi
}

# Set permissions for all certificates in the module directory
chown -R 0:0 ${MODDIR}/system/etc/security/cacerts
set_context /system/etc/security/cacerts ${MODDIR}/system/etc/security/cacerts

# Count certificates in module directory
CERT_COUNT=$(ls -1 ${MODDIR}/system/etc/security/cacerts/*.0 2>/dev/null | wc -l)
echo "Found $CERT_COUNT certificate(s) in module directory"

if [ "$CERT_COUNT" -eq 0 ]; then
    echo "No certificates found in module directory, exiting"
    exit 0
fi

# Android 14 support
# Since Magisk ignore /apex for module file injections, use non-Magisk way
if [ -d /apex/com.android.conscrypt/cacerts ]; then
    echo "Android 14+ detected, using APEX mount method"
    
    # Clone directory into tmpfs
    rm -f /data/local/tmp/sys-ca-copy
    mkdir -p /data/local/tmp/sys-ca-copy
    mount -t tmpfs tmpfs /data/local/tmp/sys-ca-copy
    
    # Copy existing system certificates
    cp -f /apex/com.android.conscrypt/cacerts/* /data/local/tmp/sys-ca-copy/
    
    # Copy all certificates from module
    cp -f ${MODDIR}/system/etc/security/cacerts/* /data/local/tmp/sys-ca-copy/
    chown -R 0:0 /data/local/tmp/sys-ca-copy
    set_context /apex/com.android.conscrypt/cacerts /data/local/tmp/sys-ca-copy

    # Mount directory inside APEX if it is valid, and remove temporary one.
    TOTAL_CERTS_NUM="$(ls -1 /data/local/tmp/sys-ca-copy | wc -l)"
    echo "Total certificates after merge: $TOTAL_CERTS_NUM"
    
    if [ "$TOTAL_CERTS_NUM" -gt 10 ]; then
        echo "Mounting certificate directory to APEX"
        mount --bind /data/local/tmp/sys-ca-copy /apex/com.android.conscrypt/cacerts
        for pid in 1 $(pgrep zygote) $(pgrep zygote64); do
            nsenter --mount=/proc/${pid}/ns/mnt -- \
                mount --bind /data/local/tmp/sys-ca-copy /apex/com.android.conscrypt/cacerts
        done
        echo "Successfully mounted $CERT_COUNT additional certificate(s)"
    else
        echo "Cancelling replacing CA storage due to safety (too few certificates)"
    fi
    umount /data/local/tmp/sys-ca-copy
    rmdir /data/local/tmp/sys-ca-copy
else
    echo "Pre-Android 14 system detected, using standard Magisk mount"
    echo "Magisk will automatically handle mounting $CERT_COUNT certificate(s)"
fi

echo "Universal CA Certificate Installer completed"
echo "Project: universal-cacert-installer"