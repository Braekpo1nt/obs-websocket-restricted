# OBS Websocket Restricted
The purpose of this is to enable specific [OBS Websocket](https://github.com/obsproject/obs-websocket) commands instead of giving cart blanc access to anyone who knows your ip, port, and password (which sounds scare to me). 

I used this method to allow my friend who I'm squad-streaming with to swap between his and my perspectives (scenes) without also being able to do anything else.

## Key terms
I use these throughout these docs and in comments.
- **OBS Machine**: The computer that has your [OBS](https://obsproject.com/) (and [OBS Websocket](https://github.com/obsproject/obs-websocket)) running on it (probably your streaming PC)
- **OBS Machine's Network**: The network that your OBS Machine exists in (probably your home network)
- **Client**: The computer you wish to control OBS from remotely (probably your friend's computer)
- **Interface VM**: The Virtual Machine which exists on the OBS Machine's Network
    - Could be a [VM](https://www.virtualbox.org/) on running on your OBS Machine, a [proxmox](https://www.proxmox.com/en/) vm, an extra computer in your closet, etc.
- **Cloudflared Tunnel VM**: The Virtual Machine which is running your Cloudflare tunnel service. [More info about setting up tunnels here](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

See the figure in [Overview of the Method](#overview-of-the-method) for a graphical representation of these terms.

## Overview of the method
The Interface VM receives specific, limited SSH commands from the Client, and sends pre-determined corresponding requests to the OBS Websocket server on the OBS Machine. Cloudflare can optionally be used to secure your Client's connection to the Interface VM. If cloudflare is not used, Port Forwarding can be used to expose your Interface VM to the internet. 

![flow diagram showing the network topography](../obs-flow.png)

# Requirements/Prerequisites
This is stuff I'm not teaching you lol.

- OBS 28.0.0 or greater (obs-websocket is pre-installed), or a lower version with the [obs-websocket](https://github.com/obsproject/obs-websocket) plugin installed.
- The port to your OBS Machine's OBS Websocket open within the OBS Machine's Network (you'll get errors saying the connection timed out if the port isn't open properly). Consult your firewall for how to do this. 
    - **DO NOT** port forward `4455` to your OBS Machine. This allows anyone on the internet who has your OBS Websocket's password to do anything they want with your OBS instance. 
- An Interface VM set up to allow SSH access from your Client. Your Client should have the private key needed to ssh into your Interface VM. This should be distinct from the private key you use to configure your Interface VM, because you want all access for yourself and limited access for your Client. 
    - If you aren't using [Cloudflare Tunnels](#cloudflare-tunnels), you'll need to configure Port Forwarding on the OBS Machine's Network to direct traffic to your Interface VM's port `22` (this allows ssh access to that VM, if you have the private key).
- The ability to SSH from your Client. Most operating systems have it built in.
- IP addresses for your OBS Machine and Interface VM that won't change (at least not frequently enough to be annoying). Check out your router settings (on the OBS Machine's Network) to see if you can manually assign a static IP address to your machines. 

## Cloudflare Tunnels
Note: Cloudflare-related requirements are only necessary to avoid opening a port on your network. 

If you want to use cloudflare tunnels instead of port forwarding, this is what you need. If you want to port forward instead, simply skip this section. If you don't know what the heck this is, skip this section and come back when you want to *extra-secure* your network. 
- A [cloudflare](cloudflare.com) account with an associated domain. For all examples, `braekpo1nt.com` is used as the domain. 
- A Cloudflared Tunnel VM with [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) installed and running, with has a [secure tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) set up to forward network traffic to services inside the OBS Machine's Network.

# Setup

## OBS Machine
- Make sure OBS is running and obs-websocket is turned on (`Tools>OBS Websocket Server Settings`)
    - Click "Show Connect Info" to see the Server IP, Port, and Password. For demonstration purposes, let's say its:
        - Server IP: `192.168.0.1`
        - Server Port: `4455`
        - Server Password: `pass@123`
- Make sure port `4455` is accessible by other devices on your network

## Client (Part 1)
- [Generate an SSH key](./ssh-key.md) for the Client to ssh into the Interface VM without a password prompt (this is more secure than a password)
- You will use the generated public key file contents (`id_ed25519.pub`) in later steps.

## Interface VM
- Add a user named `buddy`
  ```bash
  sudo adduser buddy
  ```
  When prompted, provide a password for the user and leave other information such as name, phone number, and email address blank by pressing `Enter`.
- Switch to the `buddy` user:
  ```bash
  su - buddy
  ```
- Make the `~/.ssh/` directory
  ```bash
  mkdir -p ~/.ssh
  ```
- Edit the `~/.ssh/authorized_keys` we will use `nano`
  ```bash
  nano ~/.ssh/authorized_keys
  ```
  Paste the following content into the file. This makes it so your Client can only execute the command `~/wrapper.sh` and doesn't give full shell access.
  ```
  command="~/wrapper.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-ed25519 AAAAC3....435435ljkgdfi buddy@email.com
  ```
  Be sure to replace the `ssh-ed25519 AAAAC3....435435ljkgdfi buddy@email.com` with the [actual public key](#client-part-1) that your Client has the private key for. 

### Wrapper Script
This details the creation of your wrapper script. This interprets SSH commands from the Client and translates them into obs-websocket instructions to be sent to your OBS Machine over your local network. 

The purpose of this script in combination with the `~/.ssh/authorized_keys` configuration [above](#interface-vm) allows the Client to run commands such as
```bash
ssh buddy@<host> "option"
```
In order to perform different specific actions that you pre-determined. 

See my example [wrapper.sh](./wrapper.sh) for a complete script with detailed comments.

- If you're not already, log in as your `buddy` user
  ```bash
  su - buddy
  ```
- Create `~/wrapper.sh`
  ```bash
  nano ~/wrapper.sh
  ```
  Add your [wrapper](./wrapper.sh) script contents.
- Give execute permissions
  ```bash
  chmod +x ~/wrapper.sh
  ```
- Install [obs-cmd](https://github.com/grigio/obs-cmd) according to their instructions
  - Verify that your `obs-cmd` is installed properly 
  ```bash
  obs-cmd --help
  ```
  If you get the help screen, it's installed properly
  - Verify that you can control your OBS Machine's OBS instance
  ```bash
  obs-cmd --websocket obsws://192.168.0.1:4455/passwd@123 info
  ```
  if you get a nice json block of information, then you're good to go. If you get any errors, then you'll need to troubleshoot. 
  - You're free to log out from your buddy user
  ```bash
  exit
  ```

## Cloudflare
If desired, you can use Cloudflare to securely expose your Interface VM's ssh service to the internet without opening a port and without sharing your IP address. This is highly recommended. If you don't want to do this, you can skip to the [Port Forwarding](#port-forwarding) section.

- Follow the [Connect to SSH server with **cloudflared** access](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/use-cases/ssh/#connect-to-ssh-server-with-cloudflared-access) instructions. If you prefer, here is a useful [video walkthrough](https://www.youtube.com/watch?v=lq7WpGJZvk4) of the process.
    - Ensure you've followed all the instructions, and verified that you can run the following command:
      ```bash
      ssh buddy@<host> "option1"
      ```
      from your Client machine, and that it successfully does your option (or at least says "Unrecognized option"). 

In my following examples, assume the tunnel host is `websocket.braekpo1nt.com`
```
ssh buddy@websocket.braekpo1nt.com "buddy"
# or
ssh buddy@websocket.braekpo1nt.com "braekpo1nt"
```

## Port Forwarding
If you don't want to use Cloudflare Tunneling you can opt to Forward the Port to your Interface VM's port `22` (the default interface for ssh). Log into the router for the OBS Machine's Network and find your port forwarding settings. You can decide what port on your router to forward to your Interface VM (I would use `2222`). From your client, confirm that you can use a similar command to the following to ssh into your Interface VM:
```
ssh <username>@<public-ip-address>:<forwarded-port>
```
Where `<username>` is the one you've been using to ssh into your Interface VM to configure it (NOT the username associated with your Client, e.g. `buddy`) `<public-ip-address>` is the public IP address of your OBS Machine's Network, and `<forwarded-port>` is the port your chose (e.g. `2222`). 


## Client (Part 2)
If you've gotten this far, you should be able to make ssh calls from your Client to your Interface VM over the internet. 

- If you used my [example wrapper.sh script](./wrapper.sh), then you should be able to run the following command to switch to the scene titled "Buddy Screen":
  ```bash
  ssh buddy@<host> "buddy"
  ```
- The first time you do this, you'll need to confirm that you wish to connect. Enter `yes` and press enter to the prompt:
  ```
  The authenticity of host <hostname (IP address)> can't be established.
  ECDSA key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
  Are you sure you want to continue connecting (yes/no)?
  ```
- If you're using [Cloudflare tunnels](#cloudflare) then you'll need to follow the instructions to authenticate, as described [above](#cloudflare).
  - Note that if you set an authentication period that you'll need to manually run this command every period of re-authentication. Then your automation will continue to work.

You should now be able to run your ssh commands on your Client to change OBS on your OBS Machine. Great job getting this far! In the next section, I'll detail how to set up Stream Deck keys on your Client to trigger your commands. 

### Stream Deck
If you want to be able to use Stream Deck keys to trigger the actions you pre-set in your `~/wrapper.sh` script, you can use the built-in **Open** action to run scripts associated with those triggers. 

#### Windows
- Create a batch script for each command. In our example, we have two (one for `buddy` and one for `braekpo1nt`):
  `path/to/buddy-scene.bat`:
  ```bat
  @echo off
  ssh buddy@websocket.braekpo1nt.com "buddy"
  ```
  `path/to/braekpo1nt-scene.bat`:
  ```bat
  @echo off
  ssh buddy@websocket.braekpo1nt.com "braekpo1nt"
  ```
  Replace `websocket.braekpo1nt.com` with your Cloudflare Tunnel host (or if you're using Port Forwarding, replace it with the public ip address of your OBS Machine's Network).
#### Linux/macOS
- Create a bash script for each command. In our example, we have two (one for `buddy` and one for `braekpo1nt`):
  `path/to/buddy-scene.sh`:
  ```bash
  #!/bin/bash
  ssh buddy@websocket.braekpo1nt.com "buddy"
  ```
  `path/to/braekpo1nt-scene.sh`:
  ```bash
  #!/bin/bash
  ssh buddy@websocket.braekpo1nt.com "braekpo1nt"
  ```
  Replace `websocket.braekpo1nt.com` with your Cloudflare Tunnel host (or if you're using Port Forwarding, replace it with the public ip address of your OBS Machine's Network).
- Give your scripts execute permissions
  ```bash
  sudo chmod +x path/to/buddy-scene.sh
  sudo chmod +x path/to/braekpo1nt-scene.sh
  ```

Once you've created your scripts:
- Open Stream Deck
- Add a **System>Open** key for each script
  - Title: Whatever you want (e.g. "Buddy Scene")
  - App/File: `path/to/buddy-scene.bat` (or `.sh`)

There you go! You should be able to press the Stream Deck buttons on your Client, and see the changes on your OBS Machine's instance of OBS.

# Conclusion
If you followed the [setup](#setup) instructions, you should be able to control your OBS Machine's OBS instance with your Client. 

My dad and I use this system in [our livestreams](https://youtube.com/braekpo1nt) to let each of us swap to the other's perspective when we're squad streaming. I hope this guide helped you out, too. 

Note that for this to work:
- the OBS Machine needs to have the obs-websocket turned on
- the Interface VM needs to be running
  - The SSH service needs to be functioning
  - The `cloudflared` service needs to be functioning (unless you opted to use Port Forwarding)

# Common Issues/Errors
- If the IP addresses of your OBS Machine, your Interface VM, or your OBS Machine's Network changes, you will need to update your configurations. 
- If your Interface VM is down, your Client won't be able to control your OBS Machine's OBS instance. 
- If you're using `Git Bash` for Windows (or somehow otherwise using a bash command prompt) in conjunction with the `.bat` scripts and Cloudflare Tunnels, and your Command Prompt (CMD) is giving you the following error:
  ```batch
  CreateProcessW failed error:2
  posix_spawnp: No such file or directory
  ```
  You may need to change your `~/.ssh/config` file on your Client to use Windows paths with escape characters:
  ```
  Host websocket.braekpo1nt.com
    ProxyCommand C:\\path\\to\\cloudflared.exe access ssh --hostname %h
    IdentityFile C:\\User\\username\\.ssh\\id_ed25519
  ```
  Rather than using `/c/path/to/cloudflared.exe`

# Contributing/Bug Reports
Feel free to leave a comment, make a pull request from a fork, or otherwise submit an issue on the GitHub repo to let me know how this can be improved or built upon. 

Check out the [Official Braekpo1nt Discord](https://discord.gg/2xEg8jMWmj) or my [YouTube Channel](https://youtube.com/braekpo1nt) to ask questions or see it in action. 
