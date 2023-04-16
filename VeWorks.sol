// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract VeWorks {
    address public admin;
    uint256 public serviceIdCounter;
    uint256 public messageIdCounter;
    uint256 private constant COMMISSION_RATE = 5;

 struct Service {
    uint256 id;
    address payable freelancer;
    string title;
    string description;
    string category;
    uint256 price;
    bool active;
    string imageHash;
    string videoHash;
}

    struct Rating {
        uint8 score;
        string comment;
    }

    struct Message {
        uint256 id;
        address sender;
        address recipient;
        string content;
        bool isRead;
        uint256 timestamp;
    }

    struct PortfolioItem {
        string title;
        string description;
        string link;
    }

    enum JobStatus { Pending, InProgress, Completed, Approved, Disputed, Canceled }

    struct Job {
        uint256 id;
        uint256 serviceId;
        address client;
        uint256 amount;
        JobStatus status;
    }

    mapping(uint256 => Service) public services;
    mapping(address => Rating[]) public freelancerRatings;
    mapping(address => Rating[]) public clientRatings;
    mapping(uint256 => Message) public messages;
    mapping(address => PortfolioItem[]) public portfolios;
    mapping(address => Job[]) public jobHistory;
    mapping(address => uint256) public freelancerBalances;

    event ServiceAdded(uint256 indexed serviceId, address indexed freelancer);
    event ServiceHired(uint256 indexed serviceId, address indexed client);
    event FreelancerRated(address indexed freelancer, address indexed client, uint8 score);
    event ClientRated(address indexed client, address indexed freelancer, uint8 score);
    event MessageSent(uint256 indexed messageId, address indexed sender, address indexed recipient);
    event JobStatusChanged(uint256 indexed jobId, JobStatus status);

    constructor() {
        admin = msg.sender;
        serviceIdCounter = 1;
        messageIdCounter = 1;
    }

    function addService(string memory title, string memory description, string memory category, uint256 price, string memory imageHash,
    string memory videoHash) public {
        require(price > 0, "Price must be greater than 0.");

        services[serviceIdCounter] = Service(
            serviceIdCounter,
            payable(msg.sender),
            title,
            description,
            category,
            price,
            true,
            imageHash,
            videoHash
        );

        emit ServiceAdded(serviceIdCounter, msg.sender);
        serviceIdCounter++;
    }

     function hireService(uint256 serviceId) public payable {
        Service storage service = services[serviceId];
        require(service.active, "Service not available.");
        require(msg.value == service.price, "Incorrect payment amount.");

        uint256 commission = (msg.value * COMMISSION_RATE) / 100;
        uint256 freelancerPayment = msg.value - commission;
        freelancerBalances[service.freelancer] += freelancerPayment;
        service.active = false;

        emit ServiceHired(serviceId, msg.sender);
    }

    function withdrawFunds() public {
        uint256 balance = freelancerBalances[msg.sender];
        require(balance > 0, "Insufficient funds.");

        freelancerBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function toggleService(uint256 serviceId) public {
        Service storage service = services[serviceId];
        require(service.freelancer == msg.sender, "Not authorized.");

        service.active = !service.active;
    }

    function rateFreelancer(address freelancer, uint8 score, string memory comment) public {
        require(score >= 1 && score <= 5, "Score must be between 1 and 5.");

        freelancerRatings[freelancer].push(Rating(score, comment));
emit FreelancerRated(freelancer, msg.sender, score);
}

function rateClient(address client, uint8 score, string memory comment) public {
    require(score >= 1 && score <= 5, "Score must be between 1 and 5.");

    clientRatings[client].push(Rating(score, comment));
    emit ClientRated(client, msg.sender, score);
}

function searchServicesByPrice(uint256 minPrice, uint256 maxPrice) public view returns (uint256[] memory) {
    uint256[] memory filteredServiceIds = new uint256[](serviceIdCounter);
    uint256 counter = 0;

    for (uint256 i = 1; i < serviceIdCounter; i++) {
        if (services[i].price >= minPrice && services[i].price <= maxPrice && services[i].active) {
            filteredServiceIds[counter] = i;
            counter++;
        }
    }

    uint256[] memory resultServiceIds = new uint256[](counter);
    for (uint256 i = 0; i < counter; i++) {
        resultServiceIds[i] = filteredServiceIds[i];
    }

    return resultServiceIds;
}

function searchServicesByCategory(string memory category) public view returns (uint256[] memory) {
    uint256[] memory filteredServiceIds = new uint256[](serviceIdCounter);
    uint256 counter = 0;

    for (uint256 i = 1; i < serviceIdCounter; i++) {
        if (keccak256(abi.encodePacked(services[i].category)) == keccak256(abi.encodePacked(category)) && services[i].active) {
            filteredServiceIds[counter] = i;
            counter++;
        }
    }

    uint256[] memory resultServiceIds = new uint256[](counter);
    for (uint256 i = 0; i < counter; i++) {
        resultServiceIds[i] = filteredServiceIds[i];
    }

    return resultServiceIds;
}

// Función de mensajería
function sendMessage(address recipient, string memory content) public {
    messages[messageIdCounter] = Message(
        messageIdCounter,
        msg.sender,
        recipient,
        content,
        false,
        block.timestamp
    );

    emit MessageSent(messageIdCounter, msg.sender, recipient);
    messageIdCounter++;
}

function markMessageAsRead(uint256 messageId) public {
    Message storage message = messages[messageId];
    require(message.recipient == msg.sender, "Not authorized.");

    message.isRead = true;
}

// Función para agregar elementos al portafolio
function addPortfolioItem(string memory title, string memory description, string memory link) public {
    portfolios[msg.sender].push(PortfolioItem(title, description, link));
}

// Función para cambiar el estado de un trabajo
function updateJobStatus(uint256 jobId, JobStatus newStatus) public {
    Job storage job = jobHistory[msg.sender][jobId];
    require(job.status != JobStatus.Canceled, "Job is already canceled.");

    job.status = newStatus;
    emit JobStatusChanged(jobId, newStatus);
}

// Función para manejar disputas
function raiseDispute(uint256 jobId) public {
    Job storage job = jobHistory[msg.sender][jobId];
    require(job.status != JobStatus.Disputed, "Dispute already raised.");
    require(job.status != JobStatus.Canceled, "Job is already canceled.");

    job.status = JobStatus.Disputed;
    emit JobStatusChanged(jobId, JobStatus.Disputed);
}
}
