// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

enum InsurancePolicyTypes {CropInsurance}

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
struct InsuranceCompanyData {
      bytes businessName;
	  bytes businessIdentificationNumber;
      bool registered;
      bool approved;
      address owner;
	  address admin;
    }
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

contract Farmer {

    FarmerData farmerData;

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    //error InvalidFarmerDetails(bytes nationalIdentityNumber, bytes errorDescription);

    function registerFarmer(bytes memory nationalIdentityNumber_, GpsCoordinates memory farmCoordinates_) internal returns (FarmerData memory) {
        //require(nationalIdentityNumber_.length > 0, InvalidMemberDetails(nationalIdentityNumber_, bytes("National Identity Number has invalid value.")));
        require(nationalIdentityNumber_.length > 0, "National Identity Number has invalid value.");
        farmerData.nationalIdentityNumber = nationalIdentityNumber_;
		farmerData.farmCoordinates = farmCoordinates_;
        farmerData.registered = true;
        farmerData.owner = msg.sender;

        return farmerData;
    }
}

contract InsuranceCompany {

    InsuranceCompanyData insuranceCompanyData;
	
	// Constructor code is only run when the contract
    // is created
    constructor() {
        insuranceCompanyData.admin = msg.sender;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    //error InvalidInsuranceCompanyDetails(bytes businessIdentificationNumber, bytes errorDescription);

    function registerInsuranceCompany(bytes memory businessName_, bytes memory businessIdentificationNumber_) internal returns (InsuranceCompanyData memory) {
        //require(businessIdentificationNumber_.length > 0, InvalidInsuranceCompanyDetails(businessIdentificationNumber_, bytes("Business Identification Number has invalid value.")));
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

    InsurancePolicyData insurancePolicyData;
	
	// Constructor code is only run when the contract
    // is created
    constructor() {
        insurancePolicyData.admin = msg.sender;
    }

    // Errors allow you to provide information about
    // why an operation failed. They are returned
    // to the caller of the function.
    //error InvalidInsurancePolicyDetails(bytes referenceNumber, bytes errorDescription);

    function registerInsurancePolicy(bytes memory referenceNumber_, bytes memory startDate_, bytes memory stopDate_, InsurancePolicyTypes memory policyType_, uint256 memory policyPremium_) internal returns (InsurancePolicyData memory) {
        require(msg.sender == insurancePolicyData.admin, "Signer address is not authorised to make changes.");
        require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(policyPremium_ > 0, "Policy premium amount must be greater than zero");
        insurancePolicyData.referenceNumber = referenceNumber_;
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
      //mapping(bytes => InsuranceCompanyData) insuranceCompanies;
      //mapping(bytes => InsurancePolicyData) insurancePolicies;
	  InsuranceCompanyData insuranceCompany;
	  InsurancePolicyData insurancePolicy;
      //uint256 totalPolicyPremiumCollected;
	  //uint256 totalPayments;
      //uint16 totalPolicyHolders;
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
        //InsuranceCompanyData memory insuranceCompanyData = cropInsuranceProgram.insuranceCompanies[businessIdentificationNumber_];
        //require(!insuranceCompanyData.registered, "Insurance company is already registered");
		require(!insuranceCompany.registered, "Insurance company is already registered");

        // call registerInsuranceCompany in contract InsuranceCompany
        //InsuranceCompanyData memory insuranceCompanyData_ = registerInsuranceCompany(businessName_, businessIdentificationNumber_);
        //cropInsuranceProgram.insuranceCompanies[businessIdentificationNumber_] = insuranceCompanyData_;
		insuranceCompany = registerInsuranceCompany(businessName_, businessIdentificationNumber_);
    }
	
	function registerNewInsurancePolicy(bytes memory referenceNumber_, bytes memory startDate_, bytes memory stopDate_, InsurancePolicyTypes memory policyType_, uint256 memory policyPremium_) external {
        require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(policyPremium_ > 0, "Policy premium amount must be greater than zero");

        // Check if insurance policy is already registered
        //InsurancePolicyData memory insurancePolicyData = cropInsuranceProgram.insurancePolicies[referenceNumber_];
        //require(!insurancePolicyData.initialised, "Insurance policy is already registered");
		require(!insurancePolicy.initialised, "Insurance policy is already registered");

        // call registerInsuranceCompany in contract InsurancePolicy
        //InsurancePolicyData memory insurancePolicyData_ = registerInsurancePolicy(referenceNumber_, startDate_, stopDate_, policyType_, policyPremium_);
        //cropInsuranceProgram.insurancePolicies[referenceNumber_] = insurancePolicyData_;
		insurancePolicy = registerInsurancePolicy(referenceNumber_, startDate_, stopDate_, policyType_, policyPremium_);
    }
	
	function depositFunds() external payable {
	    require(insurancePolicy.active, "Insurance policy must be active");
        require(msg.value > 0, "Deposit amount must be greater than zero");
		FarmerData memory farmerData = cropInsuranceProgram.farmers[msg.sender];
        require(farmerData.registered, "Farmer is not registered");
		require(!farmerData.insured, "Farmer is already insured");
		require(msg.value == insurancePolicy.policyPremium, "Deposit amount must be equal to policy premium amount");

        deposit();
		farmerData.insured = true;
		insurancePolicy.totalPolicyHolders += 1;
		insurancePolicy.totalPolicyPremiumCollected += msg.value;
        
    }
	
	function approveInsuranceCompany(bytes memory businessIdentificationNumber_) internal {
	    require(msg.sender == insuranceCompany.admin, "Signer address is not authorised to make changes.");
		require(businessIdentificationNumber_.length > 0, "Business Identification Number has invalid value.");
		require(insuranceCompany.businessIdentificationNumber == businessIdentificationNumber_, "Business Identification Number does not exist.");
        insuranceCompany.approved = true;
    }
	
	function activateInsurancePolicy(bytes memory referenceNumber_) internal {
	    require(msg.sender == insurancePolicy.admin, "Signer address is not authorised to make changes.");
		require(!insurancePolicy.active, "Insurance policy is already active");
		require(referenceNumber_.length > 0, "Reference Number has invalid value.");
		require(insurancePolicy.referenceNumber == referenceNumber_, "Reference Number does not exist.");
        insurancePolicy.active = true;
    }
	
	// give insurance when rains fail
}