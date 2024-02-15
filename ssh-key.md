## Generating SSH Key

### Windows:

-  Open Command Prompt: Press `Win + R`, type `cmd`, and press Enter.
-  Navigate to the directory where you want to save the SSH key, if necessary, using the `cd` command.
-  Execute the following command, replacing `<your_email@example.com>` with your email address:

```
ssh-keygen -t ed25519 -C "buddy@email.com"
```


-  Press Enter. You will be prompted to enter a file in which to save the key. Press Enter again to save it in the default location (`C:\Users\your_username\.ssh\id_ed25519`).
-  You'll be prompted to enter a passphrase for the key. You can leave it empty for no passphrase or enter one for added security.
-  Once completed, your SSH key will be generated and saved in the specified location.

### Linux:

-  Open a terminal window.
-  Navigate to the directory where you want to save the SSH key, if necessary, using the `cd` command.
-  Execute the following command, replacing `<your_email@example.com>` with your email address:


```
ssh-keygen -t ed25519 -C "buddy@email.com"
```

-  Press Enter. You will be prompted to enter a file in which to save the key. Press Enter again to save it in the default location (`/home/your_username/.ssh/id_ed25519`).
-  You'll be prompted to enter a passphrase for the key. You can leave it empty for no passphrase or enter one for added security.
-  Once completed, your SSH key will be generated and saved in the specified location.

## Adding it to authorized_keys
After generating the SSH key, you'll have two files: `id_ed25519` (private key) and `id_ed25519.pub` (public key). The public key (`id_ed25519.pub`) is what you'll share with services or servers you want to authenticate with using SSH. Make sure to keep your private key (`id_ed25519`) secure and never share it.
