// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Marketplace {

    uint internal bookDoctorLength = 0; //initialize length to zero
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

// struct to get doctor's data
    struct BookDoctor {
        address payable owner;
        string name;
        string image;
        string description;
        uint price;
        uint appointments;
        uint likes; // counter for likes
    }

    event LikeDoctor(uint index, address user, uint likes);
    event DislikeDoctor(uint index, address user, uint likes);

    mapping(uint => mapping(address => bool))liked; // keeps track of wallet likes per doctor

    mapping (uint => BookDoctor) internal bookDoctor;

    modifier isValidIndex(uint _index){
        require(_index < bookDoctorLength, "Enter a valid index");
        _;
    }

// create or register a doctor
    function writeBookDoctor(
        string memory _name,
        string memory _image,
        string memory _description, 
        uint _price
    ) public {
        require(bytes(_name).length > 0, "Enter a valid name");
        require(bytes(_image).length > 0, "Enter a valid image url");
        require(bytes(_description).length > 0, "Enter a valid description");
        require(_price > 0, "Enter a valid price");
        uint _appointments = 0;
        bookDoctor[bookDoctorLength] = BookDoctor(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _price,
            _appointments,
            0
        );
        bookDoctorLength++; //increment length after each registration
    }

// read doctors that are available
    function readBookDoctor(uint _index, address user) public view isValidIndex(_index) returns (BookDoctor memory, bool) {
        BookDoctor memory currentDoctor = bookDoctor[_index];
        require(user != address(0), "Invalid address");
        return (currentDoctor, liked[_index][user]);
    }

// book an appointment with doctor
    function payDoctor(uint _index) public payable isValidIndex(_index)  {
        require(msg.sender != bookDoctor[_index].owner, "You can't book yourself");
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            bookDoctor[_index].owner,
            bookDoctor[_index].price
          ),
          "Transfer failed."
        );
        bookDoctor[_index].appointments++;
    }
    

    // get total number of available doctors
    function getBookDoctorLength() public view returns (uint) {
        return (bookDoctorLength);
    }

    // like a particular doctor
    function likeDoctor(uint _index) public isValidIndex(_index) {
        require(!liked[_index][msg.sender], "You have already liked this doctor");
        bookDoctor[_index].likes++;
        liked[_index][msg.sender] = true;
        emit LikeDoctor(_index, msg.sender,bookDoctor[_index].likes);
    }

// unlike a particular doctor
    function unlikeDoctor(uint _index) public isValidIndex(_index) {
        require(liked[_index][msg.sender], "You haven't liked this doctor yet");
        bookDoctor[_index].likes--;
        liked[_index][msg.sender] = false;
        emit DislikeDoctor(_index, msg.sender,bookDoctor[_index].likes);
    }
}
