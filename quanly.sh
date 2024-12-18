#!/bin/bash

export LANG=C.UTF-8

read -p "Nhap domain (khong can https:// hoac http://): " domain
read -p "Nhap IP sever (vd: 1.1.1.1): " ip_sever
read -p "Nhap port sever (vd: 22): " port_sever
read -p "Nhap port firewall (vd: 24445): " port_fw

nginx_conf="/etc/nginx/conf.d/reverse_proxy.conf"

echo "Them cau hinh moi vao $nginx_conf"
cat >> $nginx_conf <<EOL

server {
    listen 443;
    server_name $domain;

    location / {
        proxy_pass http://$ip_sever:443;
    }
}
EOL

echo "Kiem tra cau hinh nginx..."
nginx -t
if [ $? -eq 0 ]; then
    echo "Khoi dong lai nginx..."
    systemctl reload nginx
else
    echo "Loi cau hinh nginx. Vui long kiem tra lai."
    exit 1
fi

socat_script="/root/$port_fw.sh"

if [ -f "$socat_script" ]; then
    echo "File $socat_script da ton tai. dang cap nhat..."
else
    echo "Tao script socat: $socat_script"
    cat > $socat_script <<EOL
#!/bin/bash
socat TCP-LISTEN:$port_fw,fork TCP:$ip_sever:$port_sever
EOL

    chmod +x $socat_script
    chmod 777 $socat_script
fi

echo "Chay socat trong screen..."
screen -dmS $port_fw bash -c "$socat_script"

echo "Da hoan thanh thiet lap cho mien: $domain voi port firewall: $port_fw"
