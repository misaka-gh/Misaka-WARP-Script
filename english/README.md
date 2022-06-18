# Misaka WARP Script

## Usage

```shell
wget -N --no-check-certificate https://raw.githubusercontents.com/Misaka-blog/Misaka-WARP-Script/master/english/misakawarp.sh && bash misakawarp.sh
```

Shortcut: `bash misakawarp.sh`

## Some of the benefits of WARP

Unlock Netlifx restriction (WARP IP got restricted in some locations)

Avoid Google Recaptcha or use Google Academic Search

Can be used as a springboard and probe for the other VPS as it can transfer data in both directions, replacing HE tunnelbroker

Telegram support for nodes built on IPv6 only VPS

IPv6-built nodes can be used on IPv4-only PassWall and ShadowSocksR Plus+

## Adjust IPv4 or IPv6 priority

The default IP priority of the VPS is used in order to prevent lost connections due to scripted priority changes during installation. If you need to configure it, you can refer to the P3Terx article (in Chinese) at

https://p3terx.com/archives/use-cloudflare-warp-to-add-extra-ipv4-or-ipv6-network-support-to-vps-servers-for-free.html#toc_8

## WARP+ or WARP Teams account access (written in Chinese)

WARP+: https://owo.misaka.rest/cfwarp-plus/

WARP Teams: https://owo.misaka.rest/cf-teams/

## Frequently Asked Questions

### 1. Why can't I connect to Wgcf-WARP or WireProxy-WARP proxy mode

1. Check https://www.cloudflarestatus.com/, if your VPS region appears after Re-routed that is unable to connect. Please wait for the official fixing

2. Hong Kong region has been restricted by CloudFlare to use third-party clients

![image](https://user-images.githubusercontent.com/96560028/160244784-25c40a97-d398-4d4f-9deb-d82c5e9b69ef.png)

### 2. 429 Too Many Requests error when applying for Wgcf-WARP or WireProxy-WARP account

![image](https://user-images.githubusercontent.com/96560028/163660825-bb989575-f165-4bd3-aa59-a8f747c4589e.png)

This problem may occur due to the busy service of WARP during some hours. Therefore, the script comes with the function of automatically retrying to apply for a WARP account until the account is applied before the next step of installing and starting WARP.

It is recommended to backup the `/etc/wireguard/wgcf-account.toml` account configuration file after installing WARP, in case the service is too busy to apply for an account in some cases, thus preventing the installation of Wgcf-WARP or WireProxy-WARP proxy mode.

### 3. How to use the backed up wgcf-account.toml account file

Just put the file in the `/root` folder and wait for the script to recognize it automatically

If you use this script to install wgcf-warp, the installation of wireproxy-warp will automatically use the wgcf-warp account configuration file, and the reverse is also true