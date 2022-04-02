# Misaka WARP 脚本 - WireProxy-WARP 代理模式

使用基于WireGuard的用户代理程序WireProxy，在VPS创建本地Socks5代理

## 使用方法

### IPv4 Only或原生双栈VPS

```shell
wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/wireproxy-warp/warp4.sh && bash warp4.sh
```

### IPv6 Only VPS

```shell
wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/wireproxy-warp/warp6.sh && bash warp6.sh
```

### 修改WireProxy端口

```shell
wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/wireproxy-warp/changeport.sh && bash changeport.sh
```

### 卸载WireProxy-WARP 代理模式

```shell
wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/wireproxy-warp/uninstall.sh && bash uninstall.sh
```

### 刷Netfilx IP

```shell
wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/wireproxy-warp/netfilx-wireproxy.sh && bash netfilx-wireproxy.sh
```

可搭配 [Screen 管理脚本](https://github.com/Misaka-blog/screenManager) 使用最佳

## 开关WireProxy WARP

启动：`systemctl start wireproxy-warp`

关闭：`systemctl stop wireproxy-warp`

设置开机自启：`systemctl enable wireproxy-warp`

取消开机自启：`systemctl disable wireproxy-warp`

## 赞助我们

![afdian-MisakaNo.jpg](https://s2.loli.net/2021/12/25/SimocqwhVg89NQJ.jpg)

## 交流群
[Telegram](https://t.me/misakanetcn)

