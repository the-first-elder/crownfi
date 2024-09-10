# ERC20 and ERC1155 Wrapper Project

This project demonstrates how to deploy and interact with ERC20 and ERC721 contracts wrapped into an ERC1155 contract using Foundry and Ethers.js.

## Prerequisites

- Node.js and npm installed
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- [Git](https://git-scm.com/) installed

## Getting Started

### 1. Clone the Project

```bash
git clone https://github.com/the-first-elder/crownfi.git
```

### 2. Install Dependencies

```bash
forge install
```

### 3. Start a Local Blockchain with Anvil

Start a local blockchain instance using Anvil:

```bash
anvil
```

This will spin up a local blockchain and provide you with a list of accounts and private keys. Note the private key of the first account, as you'll use it to deploy your contracts.

### 4. Deploy Contracts on the Local Blockchain

Run the Forge script to deploy the contracts using the private key from Anvil:

```bash
forge script script/Wrapper.s.sol --broadcast --rpc-url http://127.0.0.1:8545 --private-key <YOUR_PRIVATE_KEY>
```

Replace `<YOUR_PRIVATE_KEY>` with the private key from Anvil. And Import the `private key` into `metamask` wallet

Change RPC configuration to  `http://127.0.0.1:8545` on metamask 

After deployment, you'll see the addresses of the deployed ERC20, ERC721, and ERC1155 wrapper contracts. Note these addresses as you'll need them to interact with the front end.

### 5. Start the Front-End

Use a live server to start the HTML file and interact with the deployed contracts:

1. Open the project in your preferred code editor (e.g., VSCode).
2. Install the Live Server extension.
3. Right-click on `index.html` and select "Open with Live Server."

This will open the front end in your default browser.

### 6. Interact with the Contracts

You can now interact with the ERC20 and ERC721 contracts and see the results on the front end:

- **Deposit ERC20:** Fill in the form with the ERC20 contract address, amount, and data, then submit.
- **Deposit ERC721:** Fill in the form with the ERC721 contract address, token ID, and data, then submit.
- **Get Token URI:** Input the token ID and retrieve the URI.

### 7. Testing the Project

If you want to test the project further, you can use the following commands:

- Run tests: `forge test`
- Check test coverage: `forge coverage`

---
