This is a two-phase process. First, you must expand the "virtual hard drive" in the VMware settings. Second, you must tell Debian to use that new empty space.

### Phase 1: Expand Disk in VMware

**Note:** You must usually power off the Virtual Machine (VM) to perform this step.

1.  Shut down your Debian VM.
2.  In VMware Workstation, right-click the VM and select **Settings**.
3.  Click on **Hard Disk (SCSI/SATA)**.
4.  On the right side, click **Expand...**
5.  Enter the new desired size (e.g., change 20GB to 50GB) and click **Expand**.
6.  Click **OK** and power on the VM.

-----

### Phase 2: Expand Space Inside Debian

Once the VM boots, Debian will see a larger physical disk, but your partitions are still the old size.

**1. Open a terminal and switch to root:**

```bash
su -
# OR
sudo -i
```

**2. Check your layout:**
Run `lsblk` to see your disk structure. This determines which method you use below.

  * **Scenario A (LVM):** You see lines like `sda1`, `sda2`, and under them branches like `debian--vg-root`. This is the default for most Debian installs.
  * **Scenario B (Standard):** You just see `sda1` mounted as `/`.

-----

#### Scenario A: The LVM Method (Most Common)

If you are using LVM, you have a "Physical Volume" (partition) holding a "Volume Group," which holds your "Logical Volumes" (filesystems). You need to resize the container first, then the filesystem.

**Step 1: Resize the physical partition**
If your main LVM partition is partition 5 (usually `/dev/sda5` inside an extended partition) or partition 2 (`/dev/sda2`), you need to resize it.

*Install the cloud-guest-utils for the easiest tool:*

```bash
apt-get update && apt-get install cloud-guest-utils
```

*Grow the partition (replace `sda` and `5` with your drive and partition number from lsblk):*

```bash
# Syntax: growpart [disk] [partition-number]
growpart /dev/sda 5
```

**Step 2: Resize the LVM Physical Volume (PV)**
Tell LVM the partition is now bigger.

```bash
pvresize /dev/sda5
```

**Step 3: Extend the Logical Volume (LV)**
Assign the new free space to your root path. (Run `df -h` to find your exact mapper path, e.g., `/dev/mapper/debian--vg-root`).

```bash
# Syntax: lvextend -l +100%FREE [your-mapper-path]
lvextend -l +100%FREE /dev/mapper/debian--vg-root
```

**Step 4: Resize the Filesystem**
Finally, expand the actual filesystem to fill the volume.

```bash
resize2fs /dev/mapper/debian--vg-root
```

-----

#### Scenario B: The Standard Partition Method

If you are not using LVM, you are resizing the partition directly.

**Step 1: Install growpart**

```bash
apt-get update && apt-get install cloud-guest-utils
```

**Step 2: Expand the partition**
Identify your root partition number using `lsblk` (usually `sda1`).

```bash
# Syntax: growpart [disk] [partition-number]
growpart /dev/sda 1
```

**Step 3: Resize the filesystem**

```bash
resize2fs /dev/sda1
```

*(Note: If you are using the XFS file system instead of EXT4, use `xfs_growfs /` instead of `resize2fs`.)*

-----

### Troubleshooting: "Partition blocked"?

If `growpart` fails, it is often because a **Swap partition** is sitting at the end of the disk, blocking your root partition from growing.

If this happens, the easiest fix is to disable swap temporarily, delete the swap partition, expand your root partition, and then recreate a swap file or partition at the end.

**Quick fix for blocked partition:**

1.  `swapoff -a` (Turn off swap)
2.  Use `cfdisk` or `fdisk` to delete the swap partition.
3.  Follow the **Scenario A** or **B** steps above to resize.
4.  Recreate swap space (or create a swap file, which is easier to manage).