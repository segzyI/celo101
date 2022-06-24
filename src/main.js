//import dependenies and files

import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import marketplaceAbi from '../contract/marketplace.abi.json'
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18
const MPContractAddress = "0xb90F28e695AA8477e1f70c87a34B6bE97DA52B08"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"
const unfilledHeart = "https://img.icons8.com/office/344/like--v2.png 2x";
const filledHeart = "https://img.icons8.com/color/344/like--v1.png 2x";

// NOTE = if you are going to merge changes, 
// please redeploy contract and replace MPContractAddrss 


let kit
let contract

// Initialised array for registered doctors
let bookDoctors = []


// check if celo wallet extension is avalable
const connectCeloWallet = async function () {
  if (window.celo) {
    try {
      notification("⚠️ Please approve this DApp to use it.")
      await window.celo.enable()
      notificationOff()
      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}


// payment approval function
async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


// gets and display our balance from celo extension wallet
const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

// gets registered doctor from our smart contract
const getDoctors = async function() {
  const _bookDoctorsLength = await contract.methods.getBookDoctorLength().call();
  const _bookDoctors = []

  for (let i = 0; i < _bookDoctorsLength; i++) {
    let _bookDoctor = new Promise(async (resolve, reject) => {
      let p = await contract.methods.readBookDoctor(i, kit.defaultAccount).call(); // object for bookDoctor and boolean value for liked is returned
      resolve({
        index: i,
        owner: p[0][0],
        name: p[0][1],
        image: p[0][2],
        description: p[0][3],
        price: new BigNumber(p[0][4]),
        appointments: p[0][5],
        likes:p[0][6],
        liked: p[1]
      })
    })
    _bookDoctors.push(_bookDoctor)
  }
  bookDoctors = await Promise.all(_bookDoctors)
  
  renderDoctors()
}


// renders registed doctor into the UI
function renderDoctors() {
  document.getElementById("marketplace").innerHTML = ""
  bookDoctors.forEach((_bookDoctor) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-4"
    newDiv.innerHTML = doctorTemplate(_bookDoctor)
    document.getElementById("marketplace").appendChild(newDiv)
  })
}

// Template card for registered doctors
function doctorTemplate(_bookDoctor) {
  const buyBtn = `<div class="d-grid gap-2">
  <a class="btn btn-lg btn-outline-dark bookBtn fs-6 p-3" id=${
    _bookDoctor.index
  }>
    Book Doctor for ${_bookDoctor.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
  </a>
  </div>`;
  return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_bookDoctor.image}" alt="Dr. ${_bookDoctor.name}">
      <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
        ${_bookDoctor.appointments} Appointments
      </div>
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_bookDoctor.owner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">Dr. ${_bookDoctor.name}</h2>
        <p class="card-text mb-4" style="min-height: 82px">
          ${_bookDoctor.description}             
        </p>
        <p class="card-text mt-4">
        <img class="likes" src="${_bookDoctor.liked? filledHeart : unfilledHeart }"
        id=${ _bookDoctor.index
        } alt="${_bookDoctor.liked? "unlike" : "like"} Dr. ${_bookDoctor.name}"
        />
          <span>${_bookDoctor.likes}</span>
          ${_bookDoctor.likes > 1? "likes" : "like"}
        </p>
        ${_bookDoctor.owner == kit.defaultAccount? "" : buyBtn}
      </div>
    </div>
  `
}




// icon gottrn from address
function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

// notifies users on state of app
function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

// hides notification
function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}

window.addEventListener('load', async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getDoctors()
  notificationOff()
});


// gets registered doctor data and sends to smart contract
document
  .querySelector("#newDoctorBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newDoctorName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newDoctorDescription").value,
      // document.getElementById("newLocation").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Adding Dr. ${params[0]}...`)
    try {
      const result = await contract.methods
        .writeBookDoctor(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 You successfully added Dr. ${params[0]}.`)
    getDoctors()
  })


// function for users to book appointment
  document.querySelector("#marketplace").addEventListener("click", async (e) => {
    if (e.target.className.includes("bookBtn")) {
      const index = e.target.id
      notification("⌛ Waiting for payment approval...")
      try {
        await approve(bookDoctors[index].price)
      } catch (error) {
        notification(`⚠️ ${error}.`)
      }
      notification(`⌛ Awaiting payment for Dr. ${bookDoctors[index].name}...`)
    try {
      const result = await contract.methods
        .payDoctor(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully booked Dr. ${bookDoctors[index].name}.`)
      getDoctors()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})



// like and unlike
document.querySelector("#marketplace").addEventListener("click", async (e) => {
  
  if (e.target.className.includes("likes")) {
    const index = e.target.id
    const account = await kit.web3.eth.getAccounts();

    // check if account already likes then unlikes
  if(bookDoctors[index].liked) {
    try {
      const result = await contract.methods
        .unlikeDoctor(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You unliked Dr. ${bookDoctors[index].name}.`)
      getDoctors()
      getBalance()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
// if account has not liked then like
  else{
    try {
    const result = await contract.methods
      .likeDoctor(index)
      .send({ from: kit.defaultAccount })
    notification(`🎉 You liked Dr. ${bookDoctors[index].name}.`)
    getDoctors()
    getBalance()
  } catch (error) {
    notification(`⚠️ ${error}.`)
  }
 }
}
})
