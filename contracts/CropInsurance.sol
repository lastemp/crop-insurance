// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Farmer {
    struct GpsCoordinates {
      bytes latitude;
	  bytes longitude;
    }
    struct FarmerData {
      bytes nationalIdentityNumber;
	  GpsCoordinates farmCoordinates;
      bool registered;
      bool insured;
      address owner;
    }

    FarmerData farmerData;

    function registerFarmer(bytes memory nationalIdentityNumber_, GpsCoordinates memory farmCoordinates_) internal returns (FarmerData memory) {
        require(nationalIdentityNumber_.length > 0, "National Identity Number has invalid value.");
        farmerData.nationalIdentityNumber = nationalIdentityNumber_;
		farmerData.farmCoordinates = farmCoordinates_;
        farmerData.registered = true;
        farmerData.owner = msg.sender;

        return farmerData;
    }
}

contract InsuranceCompany {
    struct InsuranceCompanyData {
      bytes businessName;
	  bytes businessIdentificationNumber;
      bool registered;
      bool approved;
      address owner;
	  address admin;
    }

    InsuranceCompanyData insuranceCompanyData;
	
	// Constructor code is only run when the contract
    // is created
    constructor() {
        insuranceCompanyData.admin = msg.sender;
    }

    function registerInsuranceCompany(bytes memory businessName_, bytes memory businessIdentificationNumber_) internal returns (InsuranceCompanyData memory) {
        require(businessName_.length > 0, "Business Name has invalid value.");
		require(businessIdentificationNumber_.length > 0, "Business Identification Number has invalid value.");
        insuranceCompanyData.businessName = businessName_;
		insuranceCompanyData.businessIdentificationNumber = businessIdentificationNumber_;
        insuranceCompanyData.registered = true;
        insuranceCompanyData.owner = msg.sender;

        return insuranceCompanyData;
    }
	
}

contract InsurancePolicy {
    enum InsurancePolicyTypes {CropInsurance}

struct InsurancePolicyData {
      bytes referenceNumber;
	  bytes startDate;
	  bytes stopDate;
	  InsurancePolicyTypes policyType;
      uint256 policyPremium;
      uint256 totalPolicyPremiumCollected;
	  uint256 totalPayments;
      bool active;
      uint16 totalPolicyHolders;
      bool initialised;
      address admin;
    }

    InsurancePolicyData insurancePolicyData;
	
	// Constructor code is only run when the contract
    // is created
    constructor() {
        insurancePolicyData.admin = msg.sender;
    }

    function registerInsurancePolicy(bytes memory referenceNumber_, bytes memory startDate_, bytes memory stopDate_, InsurancePolicyTypes policyType_, uint256 policyPremium_) internal returns (InsurancePolicyData memory) {
        require(msg.sender == insurancePolicyData.admin, "Signer address is not authorised to make changes.");
        require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(policyPremium_ > 0, "Policy premium amount must be greater than zero");
        insurancePolicyData.referenceNumber = referenceNumber_;
        insurancePolicyData.startDate = startDate_;
	    insurancePolicyData.stopDate = stopDate_;
	    insurancePolicyData.policyType = policyType_;
        insurancePolicyData.active = true;
        insurancePolicyData.initialised = true;

        return insurancePolicyData;
    }
}

contract Vault {
    // Mapping to store each Policy holder's deposited balance
    mapping(address => uint256) public balances;

    // Address of the contract owner (admin)
    address public admin;

    // Event to log deposits
    event Deposit(address indexed member, uint256 amount);

    // Event to log withdrawals
    event Withdraw(address indexed admin, uint256 amount);

    // Constructor to set the contract admin
    constructor() {
        admin = msg.sender;
    }

    // Modifier to restrict access to admin-only functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    // Function for Policy holders to deposit funds into the vault
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // Update the sender's balance
        balances[msg.sender] += msg.value;

        // Emit deposit event
        emit Deposit(msg.sender, msg.value);
    }

    // Function to check the vault's total balance, restricted to the admin only
    function getVaultBalance() external onlyAdmin view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw funds, restricted to the admin only
    function withdraw(uint256 amount_) external onlyAdmin {
        require(amount_ > 0, "Withdraw amount must be greater than zero");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        require(balance > amount_, "Insufficient funds");

        // Transfer the withdrawal amount to the admin
        payable(admin).transfer(amount_);

        // Emit withdraw event
        emit Withdraw(admin, amount_);
    }

    // Function to check an individual member's balance
    function getMemberBalance(address _member) external view returns (uint256) {
        return balances[_member];
    }
}

contract CropInsuranceProgram is Farmer, InsuranceCompany, InsurancePolicy, Vault {
    struct CropInsuranceProgramData {
      mapping(address => FarmerData) farmers;
	  InsuranceCompanyData insuranceCompanyData;
	  InsurancePolicyData insurancePolicyData;
      address admin;
    }

    CropInsuranceProgramData cropInsuranceProgram;

    // Constructor code is only run when the contract
    // is created
    constructor() {
        cropInsuranceProgram.admin = msg.sender;
    }

    function registerNewFarmer(bytes memory nationalIdentityNumber_, GpsCoordinates memory farmCoordinates_) external {
        require(nationalIdentityNumber_.length > 0, "National Identity Number has invalid value.");

        // Check if farmer is already registered
        FarmerData memory farmerData = cropInsuranceProgram.farmers[msg.sender];
        require(!farmerData.registered, "Farmer is already registered");

        // call registerFarmer in contract Farmer
        FarmerData memory farmerData_ = registerFarmer(nationalIdentityNumber_, farmCoordinates_);
        cropInsuranceProgram.farmers[msg.sender] = farmerData_;
    }
	
	function registerNewInsuranceCompany(bytes memory businessName_, bytes memory businessIdentificationNumber_) external {
        require(businessName_.length > 0, "Business Name has invalid value.");
		require(businessIdentificationNumber_.length > 0, "Business Identification Number has invalid value.");

        // Check if insurance company is already registered
        InsuranceCompanyData memory insuranceCompanyData = cropInsuranceProgram.insuranceCompanyData;
		require(!insuranceCompanyData.registered, "Insurance company is already registered");

        // call registerInsuranceCompany in contract InsuranceCompany
		cropInsuranceProgram.insuranceCompanyData = registerInsuranceCompany(businessName_, businessIdentificationNumber_);
    }
	
	function registerNewInsurancePolicy(bytes memory referenceNumber_, bytes memory startDate_, bytes memory stopDate_, InsurancePolicyTypes policyType_, uint256 policyPremium_) external {
        require(msg.sender == insurancePolicyData.admin, "Signer address is not authorised to make changes.");
        require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(policyPremium_ > 0, "Policy premium amount must be greater than zero");

        // Check if insurance policy is already registered
        InsurancePolicyData memory insurancePolicyData = cropInsuranceProgram.insurancePolicyData;
		require(!insurancePolicyData.initialised, "Insurance policy is already registered");

        // call registerInsurancePolicy in contract InsurancePolicy
		cropInsuranceProgram.insurancePolicyData = registerInsurancePolicy(referenceNumber_, startDate_, stopDate_, policyType_, policyPremium_);
    }
	
	function depositFunds() external payable {
	    require(insurancePolicyData.active, "Insurance policy must be active");
        require(msg.value > 0, "Deposit amount must be greater than zero");
		FarmerData memory farmerData = cropInsuranceProgram.farmers[msg.sender];
        require(farmerData.registered, "Farmer is not registered");
		require(!farmerData.insured, "Farmer is already insured");
		require(msg.value == insurancePolicyData.policyPremium, "Deposit amount must be equal to policy premium amount");

        deposit();
		farmerData.insured = true;
		insurancePolicyData.totalPolicyHolders += 1;
		insurancePolicyData.totalPolicyPremiumCollected += msg.value;
        
    }
	
	function approveInsuranceCompany(bytes memory businessIdentificationNumber_) external {
	    require(msg.sender == insuranceCompanyData.admin, "Signer address is not authorised to make changes.");
		require(businessIdentificationNumber_.length > 0, "Business Identification Number has invalid value.");
        require(compareBytes(insuranceCompanyData.businessIdentificationNumber, businessIdentificationNumber_), "Business Identification Number does not exist.");
        insuranceCompanyData.approved = true;
    }
	
	function activateInsurancePolicy(bytes memory referenceNumber_) external {
	    require(msg.sender == insurancePolicyData.admin, "Signer address is not authorised to make changes.");
		require(!insurancePolicyData.active, "Insurance policy is already active");
		require(referenceNumber_.length > 0, "Reference Number has invalid value.");
        require(compareBytes(insurancePolicyData.referenceNumber, referenceNumber_), "Reference Number does not exist.");
        insurancePolicyData.active = true;
    }
	
	function compareBytes(bytes memory a, bytes memory b) private pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }
	
	function getFarmerData(address farmer_) external view returns (FarmerData memory) {
        return cropInsuranceProgram.farmers[farmer_];
    }
	
	function getInsuranceCompanyData() external view returns (InsuranceCompanyData memory) {
        return cropInsuranceProgram.insuranceCompanyData;
    }
	
	function getInsurancePolicyData() external view returns (InsurancePolicyData memory) {
        return cropInsuranceProgram.insurancePolicyData;
    }
}