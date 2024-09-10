document.addEventListener("DOMContentLoaded", async function () {
  if (typeof window.ethereum !== "undefined") {
    console.log("MetaMask is available!");

    await window.ethereum.request({ method: "eth_requestAccounts" });
    const provider = new ethers.providers.Web3Provider(window.ethereum);

    const localNetwork = {
      chainId: "0x7a69", // 1337 in hex, which is the default chain ID for Anvil/Ganache
      chainName: "Localhost 8545",
      rpcUrls: ["http://127.0.0.1:8545"],
      nativeCurrency: {
        name: "ETH",
        symbol: "ETH",
        decimals: 18,
      },
      blockExplorerUrls: null,
    };

    try {
      await window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [localNetwork],
      });
      console.log("Local network added!");

      const signer = provider.getSigner();

      const erc20Data = await fetch("./out/MockERC20.sol/MockERC20.json");
      const contractData = await erc20Data.json();
      const erc20abi = contractData.abi;

      // erc721 abi ......

      const erc721Data = await fetch("./out/MockERC721.sol/MockERC721.json");
      const contractData_721 = await erc721Data.json();
      const erc721abi = contractData_721.abi;

      //   wrapper abi

      const warpperData = await fetch("./out/Wrapper.sol/Wrapper.json");
      const response = await warpperData.json();
      const warpperabi = response.abi;

      // Create a signer using the private key
      const wrapperAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // Replace with your wrapper contract address

      const wrapperContract = new ethers.Contract(
        wrapperAddress,
        warpperabi,
        signer
      );

      // Form for Depositing ERC20 Tokens
      const erc20Form = document.getElementById("erc20-deposit-form");
      erc20Form.addEventListener("submit", async function (event) {
        event.preventDefault();

        const erc20Address = document.getElementById("erc20-address").value;
        const erc20Amount = document.getElementById("erc20-amount").value;
        const erc20Data = document.getElementById("erc20-data").value || "0x";

        const erc20Contract = new ethers.Contract(
          erc20Address,
          erc20abi,
          signer
        );

        try {
          const tx = await erc20Contract.approve(
            wrapperAddress,
            ethers.utils.parseUnits(erc20Amount, 18)
          );
          await tx.wait();
          console.log("ERC20 approved for transfer:", tx.hash);
          // console.log(signer.getAddress());
          const mintx = await erc20Contract.mint(
            signer.getAddress(),
            erc20Amount
          );
          await mintx.wait();
          console.log("ERC20 minted:", mintx.hash);

          const depositERC20 = await wrapperContract.depositERC20(
            signer.getAddress(),
            erc20Address,
            erc20Amount,
            erc20Data
          );
          const receipt = await depositERC20.wait();
          console.log("ERC1155 id:", receipt.events[1].args.id.toString());
        } catch (err) {
          console.error("Error ", err);
        }
      });

      // WithdrawERC20................

      const withdrawerc721Form = document.getElementById("withdrawERC20Form");
      withdrawerc721Form.addEventListener("submit", async function (event) {
        event.preventDefault();
        const erc20Address = document.getElementById(
          "withdrawErc20Address"
        ).value;
        const erc20Amount = ethers.BigNumber.from(
          document.getElementById("withdrawErc20Amount").value
        );

        try {
          const tx = await wrapperContract.withdrawERC20(
            erc20Address,
            erc20Amount
          );
          await tx.wait();
          console.log("ERC20 Withdrawal Successful", tx.hash);
        } catch (error) {
          console.error("Error:", error);
        }
      });

      // Form for Depositing ERC721 Tokens
      const erc721Form = document.getElementById("erc721-deposit-form");
      erc721Form.addEventListener("submit", async function (event) {
        event.preventDefault();

        const erc721Address = document.getElementById("erc721-address").value;
        const erc721TokenId = document.getElementById("erc721-tokenId").value;
        const erc721Data = document.getElementById("erc721-data").value || "0x";
        const erc721Contract = new ethers.Contract(
          erc721Address,
          erc721abi,
          signer
        );

        try {
          const mintx = await erc721Contract.safeMint(
            signer.getAddress(),
            "nft uri for token id"
          );
          await mintx.wait();
          console.log("ERC721 minted:", mintx.hash);
          const tokenURI = await erc721Contract.tokenURI(erc721TokenId);
          console.log(tokenURI);
          const tx = await erc721Contract.approve(
            wrapperAddress,
            erc721TokenId
          );
          await tx.wait();
          console.log("ERC721 approved for transfer:", tx.hash);

          const depositERC721 = await wrapperContract.depositERC721(
            erc721Address,
            erc721TokenId,
            erc721Data,
            tokenURI // a modified metadata for 1155 passed here...
          );
          const receipt = await depositERC721.wait();
          console.log("erc1155 ID:", receipt.events[1].args.id.toString());
        } catch (err) {
          console.error("Error :", err);
        }
      });

      // FORM for withdrawing erc721
      const withdrawERC721Form = document.getElementById("withdrawERC721Form");
      withdrawERC721Form.addEventListener("submit", async function (event) {
        event.preventDefault();
        const erc721Address = document.getElementById(
          "withdrawErc721Address"
        ).value;
        const erc721TokenId = document.getElementById(
          "withdrawErc721TokenId"
        ).value;

        try {
          const tx = await wrapperContract.withdrawERC721(
            erc721Address,
            erc721TokenId
          );
          await tx.wait();
          console.log("ERC721 Withdrawal Successful", tx.hash);
        } catch (error) {
          console.error("Error:", error);
        }
      });

      // Form to View URI by Token ID
      const uriForm = document.getElementById("view-uri-form");
      uriForm.addEventListener("submit", async function (event) {
        event.preventDefault();

        const tokenId = document.getElementById("token-id").value;

        try {
          const uri = await wrapperContract.uri(tokenId);
          console.log("Token URI:", uri);
        } catch (err) {
          console.error("Error fetching token URI:", err);
        }
      });
    } catch (switchError) {
      console.error("Failed to switch network:", switchError);
    }
  } else {
    console.log("Ethereum provider is not available. Please install MetaMask!");
  }
});

// forge script script/Wrapper.s.sol --broadcast --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
