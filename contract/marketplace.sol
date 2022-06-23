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
    event CreateDoctor(uint256, string);
    event LikeDoctor(uint256);
    event UnLikeDoctor(uint256);
    event PayDoctor(uint256, uint256);

    // struct to get doctor's data
    struct BookDoctor {
        address payable owner;
        string name;
        string image;
        string description;
        uint price;
        uint appointments;
        uint likesCount;
    }

    // map struct
    mapping (uint => BookDoctor) internal bookDoctor;
    mapping(uint => mapping(address => bool)) internal likes;



    // create or register a doctor
    function writeBookDoctor(
        string memory _name,
        string memory _image,
        string memory _description, 
        uint _price
    ) public {
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
        
        emit CreateDoctor(bookDoctorLength, _name);
        bookDoctorLength++; //increment length after each registration
    }

    // read doctors that are available
    function readBookDoctor(uint _index) public view returns (
        address payable,
        string memory, 
        string memory, 
        string memory, 
        uint, 
        uint,
        uint
    ) {
        return (
            bookDoctor[_index].owner,
            bookDoctor[_index].name, 
            bookDoctor[_index].image, 
            bookDoctor[_index].description, 
            bookDoctor[_index].price,
            bookDoctor[_index].appointments,
            bookDoctor[_index].likesCount
        );
    }

    // book an appointment with doctor
    function payDoctor(uint _index) public payable  {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            bookDoctor[_index].owner,
            bookDoctor[_index].price
          ),
          "Transfer failed."
        );

        emit PayDoctor(_index, bookDoctor[_index].price);
        bookDoctor[_index].appointments++;
    }
    

    // get total number of available doctors
    function getBookDoctorLength() public view returns (uint) {
        return (bookDoctorLength);
    }

    // like a particular doctor
    function likeDoctor(uint _index) public {
        require(!likes[_index][msg.sender], "You have already liked this doctor");
        likes[_index][msg.sender] = true;
        bookDoctor[_index].likesCount++;
        emit LikeDoctor(_index);
    }

    // unlike a particular doctor
    function unlikeDoctor(uint _index) public {
        require(likes[_index][msg.sender], "You first have to like this doctor");
        likes[_index][msg.sender] = false;
        bookDoctor[_index].likesCount--;
        emit UnLikeDoctor(_index);
    }
}