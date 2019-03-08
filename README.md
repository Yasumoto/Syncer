# ⤴️ Syncer

`Syncer <hostname> <remote_path>`

Given a target hostname and a destination folder, wait for the file to be re-written
then `scp` the file onto the remote server.

The example below will make sure your local changes in your home directory's `myrepo` directory will be syncronized with a `/home/joe/myrepo` folder. Note that you *do not* attach `myrepo` to the destination name.

```
cd /Users/joe/myrepo && Syncer remoteserver.bjoli.com /home/joe
```
