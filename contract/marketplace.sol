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
        // string location;
        uint price;
        uint appointments;
        address[] likes;
    }

// map struct
    mapping (uint => BookDoctor) internal bookDoctor;


// create or register a doctor
    function writeBookDoctor(
        string memory _name,
        string memory _image,
        string memory _description, 
        // string memory _location, 
        uint _price
    ) public {
        uint _appointments = 0;
        address[] memory _likes;
        bookDoctor[bookDoctorLength] = BookDoctor(
            payable(msg.sender),
            _name,
            _image,
            _description,
            // _location,
            _price,
            _appointments,
            _likes
        );
        bookDoctorLength++; //increment length after each registration
    }

// read doctors that are available
    function readBookDoctor(uint _index) public view returns (
        address payable,
        string memory, 
        string memory, 
        string memory, 
        // string memory, 
        uint, 
        uint,
        address[] memory likes
    ) {
        return (
            bookDoctor[_index].owner,
            bookDoctor[_index].name, 
            bookDoctor[_index].image, 
            bookDoctor[_index].description, 
            // bookDoctor[_index].location, 
            bookDoctor[_index].price,
            bookDoctor[_index].appointments,
            bookDoctor[_index].likes
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
        bookDoctor[_index].appointments++;
    }
    

    // get total number of available doctors
    function getBookDoctorLength() public view returns (uint) {
        return (bookDoctorLength);
    }

    // like a particular doctor
    function likeDoctor(uint _postLiked) public {
        bookDoctor[_postLiked].likes.push(payable(msg.sender));
    }

// unlike a particular doctor
    function unlikeDoctor(uint _postUnliked) public {
        address[] storage likesDoctorArr = bookDoctor[_postUnliked].likes;
        for (uint256 i = 0; i < likesDoctorArr.length; i++) {
            if (likesDoctorArr[i] == payable(msg.sender)) {
                // replace the element to delete with the last element in array
                likesDoctorArr[i] = likesDoctorArr[likesDoctorArr.length - 1];
                likesDoctorArr.pop(); // remove the last element
                break;
            }
        }
    }
}