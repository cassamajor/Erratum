/etc/ssh/sshd_config:
  file.managed:
    - source: salt://files/sshd_config
    - backup: minion

moduli:
# All Diffie-Hellman moduli in use should be at least 3072-bit-long
  cmd.run:
    - name: "awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.tmp && mv /etc/ssh/moduli.tmp /etc/ssh/moduli"

/etc/security/limits.conf:
  file.append:
    - text: "* hard core 0"

/etc/sysctl.conf:
  file.append:
    - text: "fs.suid_dumpable = 0"
    - text: "kernel.randomize_va_space = 2"
    - text: "net.ipv4.conf.all.log_martians=1"
    - text: "net.ipv4.conf.default.log_martians=1"
    - text: "net.ipv4.icmp_echo_ignore_broadcasts=1"
    - text: "net.ipv4.tcp_syncookies=1"
    - text: 'net.ipv6.conf.all.disable_ipv6 = 1'
    - text: 'net.ipv6.conf.default.disable_ipv6 = 1'
  cmd.run:
    - name: "sysctl -p"
 
/etc/pam.d/su:
  file.append:
    - text: "auth required pam_wheel.so use_uid"

authconfig --passalgo=sha512 --update:
  cmd.run: []
