Extract the tarball contents to /lib/firmware/brcm in Linux and run the following in the Linux terminal:

```bash
sudo modprobe -r brcmfmac_wcc
sudo modprobe -r brcmfmac
sudo modprobe brcmfmac
sudo modprobe -r hci_bcm4377
sudo modprobe hci_bcm4377
```

