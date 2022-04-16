# Misaka WARP 脚本

支持手工菜单+全自动化脚本安装。支持AMD64、ARM64和S390X CPU架构的VPS、支持KVM、ZVM、OpenVZ和LXC虚拟化架构的VPS

已集成至：https://github.com/Misaka-blog/Xray-script

## 使用方法

```shell
wget -N https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/misakawarp.sh && bash misakawarp.sh
```

快捷方式 `bash misakawarp.sh`

## 调整IPv4或IPv6优先

为了防止安装时脚本修改优先级情况导致失联，故使用VPS的默认IP优先级。如有需要配置可以参考P3Terx的文章：

https://p3terx.com/archives/use-cloudflare-warp-to-add-extra-ipv4-or-ipv6-network-support-to-vps-servers-for-free.html#toc_8

## 各客户端差异及对比

![image](https://user-images.githubusercontent.com/96560028/160945334-9572ec6d-7b10-4081-a83a-2d1c475ea2e3.png)

## WARP+或WARP Teams账户获取

WARP+：https://owo.misaka.rest/cfwarp-plus/

WARP Teams：https://owo.misaka.rest/cf-teams/

## 常见问题

### 1. 为什么连不上Wgcf-WARP或WireProxy-WARP代理模式

查看 https://www.cloudflarestatus.com/ ，如你的VPS区域后面出现Re-routed即为无法连接。请等待官方修复

![image](https://user-images.githubusercontent.com/96560028/160244784-25c40a97-d398-4d4f-9deb-d82c5e9b69ef.png)

### 2. 在申请Wgcf-WARP或WireProxy-WARP账号出现429 Too Many Requests错误

![image](https://user-images.githubusercontent.com/96560028/163660825-bb989575-f165-4bd3-aa59-a8f747c4589e.png)

由于这个时间段WARP的服务繁忙，可能会拒绝访问。因此脚本自带重试申请账号功能，直到申请到账号才过下一步的安装启动WARP工作

## 赞助我们

![afdian-MisakaNo.jpg](https://s2.loli.net/2021/12/25/SimocqwhVg89NQJ.jpg)

## 交流群
[Telegram](https://t.me/misakanetcn)

## 鸣谢列表

Fscarmen：https://github.com/fscarmen/warp

P3Terx：https://github.com/P3TERX/warp.sh

WireProxy：https://github.com/octeep/wireproxy

Wgcf：https://github.com/ViRb3/wgcf

CloudFlare WARP Linux Client：https://blog.cloudflare.com/zh-cn/announcing-warp-for-linux-and-proxy-mode-zh-cn/
