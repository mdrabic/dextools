dextools
========
Support tools to aid in the odexing and deodexing process on Android. 

So you have modified some dex code and put it back into the jar that 
contains odexed code. If you pushed the modified dex code back onto the 
device and hoped it would just optimize the dex code, you probably found out
that it didn't and your stuck at the boot animation. 

The gen0dex.sh script is here to help! It will push the jar that needs 
optimizing to the folder you specify on the device and optimize it. Be sure
to checkout the caveats/assumptions in the script!


