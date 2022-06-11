# VPSFree.fr WARP 定制版脚本

由于VPSFree未能对原生TUN支持，经过之前博客和Hax群友们的检测，发现其架构即使不开TUN也能正常启用WARP。但是会不太稳定。我已经在和站长沟通想办法增加原生TUN支持了！

站长回复：由于Proxmox架构API限制，暂时不能启用原生TUN模块

## 使用方法

```shell
wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/special/vpsfree.sh -O misakawarp.sh && bash misakawarp.sh
```

快捷方式 `bash misakawarp.sh`
