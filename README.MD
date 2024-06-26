# Tutorial: How to start your digital life?

## Step 1: Create your identity (dfx)

## Step 2: Send ICPs to your identity (Optional)

## Step 3: Replace the name variable by your name

- In `main.mo` replace the `name` variable by the name you want to have in Reboot.

## Step 4: Create the canister (on the European subnet)

`dfx canister create you --subnet bkfrj-6k62g-dycql-7h53p-atvkj-zg4to-gaogh-netha-ptybj-ntsgw-rqe --network ic --with-cycles 1_000_000_000_000`

## Step 5: Deploy the module inside

`dfx deploy --network ic you`

## Step 6: Perform your first daily-check

`dfx canister call --network ic you reboot_dailyCheck '("hello_world!")`

Welcome to Reboot!
