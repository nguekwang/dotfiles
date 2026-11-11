---
name: network-recovery
description: Handling network errors by reconnecting to the yunai Wi-Fi network with `nmcli d w c yunai`. Use whenever a command fails due to a connectivity problem, e.g. `git push`/`git clone`, `curl`·`web_fetch`·web searches, or package installation.
---

# Network Error Recovery

When a network-caused error occurs, reconnect to the yunai Wi-Fi network with `nmcli d w c yunai`, verify recovery, and then retry the failed command.

## Applicability (classify the error)

First determine whether the error is network-caused or caused by the target server, authentication, and so on.

| Error | Cause |
| --- | --- |
| `Could not resolve host` / `Name or service not known` / `Network is unreachable` | Network → apply |
| Connection timeouts / tools hanging on send-receive | Network → apply |
| `git` push/clone interrupted by a transport failure | Network → apply |
| `404` / `403` / `Authentication failed` / `Permission denied` | Server / auth → do not apply |

## Procedure

### 1. Check the current connection state

```sh
nmcli -t -f IN-USE,SSID dev wifi
```

If `*:yunai` is shown, the network is already connected, so the fault is likely not a Wi-Fi drop; skip this procedure and suspect the router or Ethernet side. If `yunai` does not appear in the list at all, the connection profile is probably not saved.

### 2. Attempt to reconnect to yunai

```sh
nmcli d w c yunai
```

`nmcli d w c` is short for `nmcli device wifi connect`. With a saved profile in NetworkManager, it connects without prompting for a password.

### 3. Verify recovery

```sh
nmcli -t -f IN-USE,SSID dev wifi
ping -c 1 -W 2 8.8.8.8
```

Recovery is successful when `*:yunai` is shown and ping reaches 8.8.8.8.

### 4. Retry the failed command

After confirming recovery, rerun the original command as-is.

## Rationale

NetworkManager manages the Wi-Fi connection state. `nmcli device wifi connect yunai` re-associates the link without a reboot or manual GUI steps, which is the cheapest recovery before escalating to anything heavier.

## Residuals

- If a password is required but no profile is saved, `nmcli d w c yunai` fails. Do not guess the password; ask the user.
- If connectivity does not recover, stop after about two attempts and report the situation to the user instead of retrying indefinitely (power-cycling the router or modem is the user's call).