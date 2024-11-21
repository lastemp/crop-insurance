import { expect } from "chai";
import { CropInsuranceProgram } from "../typechain-types";
import { ethers } from "ethers"; // For utility functions
import { ethers as hardhatEthers } from "hardhat"; // For Hardhat functions

describe("CropInsuranceProgram", function () {
  let cropInsuranceProgram: CropInsuranceProgram;
  let admin: any;
  let farmer: any;
  let insuranceCompany: any;

  beforeEach(async function () {
    [admin, farmer, insuranceCompany] = await hardhatEthers.getSigners();
    const CropInsuranceProgram = await hardhatEthers.getContractFactory("CropInsuranceProgram", admin);
    cropInsuranceProgram = await CropInsuranceProgram.deploy();
  });

  it("should register a new farmer", async function () {
    const nationalIdentityNumber = ethers.encodeBytes32String("1234567890");
    const latitude = ethers.encodeBytes32String("25.276987");
    const longitude = ethers.encodeBytes32String("55.296249");

    await cropInsuranceProgram.connect(farmer).registerNewFarmer(nationalIdentityNumber, { latitude, longitude });
	const farmerData = await cropInsuranceProgram.getFarmerData(
      farmer.address
    );

    expect(farmerData.registered).to.be.true;
    expect(farmerData.owner).to.equal(farmer.address);
  });

  it("should register a new insurance company", async function () {
    const businessName = ethers.encodeBytes32String("InsureCo");
    const businessIdentificationNumber = ethers.encodeBytes32String("9876543210");

    await cropInsuranceProgram.connect(insuranceCompany).registerNewInsuranceCompany(businessName, businessIdentificationNumber);
	const insuranceCompanyData = await cropInsuranceProgram.getInsuranceCompanyData();

    expect(insuranceCompanyData.registered).to.be.true;
    expect(insuranceCompanyData.owner).to.equal(insuranceCompany.address);
  });

  it("should approve the insurance company", async function () {
    const businessIdentificationNumber = ethers.encodeBytes32String("9876543210");

    await cropInsuranceProgram.connect(insuranceCompany).registerNewInsuranceCompany(
      ethers.encodeBytes32String("InsureCo"),
      businessIdentificationNumber
    );
    
    await cropInsuranceProgram.connect(admin).approveInsuranceCompany(businessIdentificationNumber);
    const insuranceCompanyData = await cropInsuranceProgram.getInsuranceCompanyData();

    expect(insuranceCompanyData.approved).to.be.true;
  });

  it("should register a new insurance policy", async function () {
    const referenceNumber = ethers.encodeBytes32String("POL12345");
    const startDate = ethers.encodeBytes32String("2024-01-01");
    const stopDate = ethers.encodeBytes32String("2025-01-01");
    const policyType = 0; // CropInsurance
    const policyPremium = ethers.parseEther("1");

    await cropInsuranceProgram.connect(admin).registerNewInsurancePolicy(
      referenceNumber,
      startDate,
      stopDate,
      policyType,
      policyPremium
    );
	const insurancePolicyData = await cropInsuranceProgram.getInsurancePolicyData();

    expect(insurancePolicyData.initialised).to.be.true;
    expect(insurancePolicyData.policyPremium).to.equal(policyPremium);
  });

  it("should activate the insurance policy", async function () {
    const referenceNumber = ethers.encodeBytes32String("POL12345");
    const startDate = ethers.encodeBytes32String("2024-01-01");
    const stopDate = ethers.encodeBytes32String("2025-01-01");
    const policyType = 0; // CropInsurance
    const policyPremium = ethers.parseEther("1");

    await cropInsuranceProgram.connect(admin).registerNewInsurancePolicy(
      referenceNumber,
      startDate,
      stopDate,
      policyType,
      policyPremium
    );
    await cropInsuranceProgram.connect(admin).activateInsurancePolicy(referenceNumber);

    const insurancePolicyData = await cropInsuranceProgram.getInsurancePolicyData();
    expect(insurancePolicyData.active).to.be.true;
  });

  it("should allow farmer to deposit funds", async function () {
    const nationalIdentityNumber = ethers.encodeBytes32String("1234567890");
    const latitude = ethers.encodeBytes32String("25.276987");
    const longitude = ethers.encodeBytes32String("55.296249");

    await cropInsuranceProgram.connect(farmer).registerNewFarmer(nationalIdentityNumber, { latitude, longitude });

    const referenceNumber = ethers.encodeBytes32String("POL12345");
    const startDate = ethers.encodeBytes32String("2024-01-01");
    const stopDate = ethers.encodeBytes32String("2025-01-01");
    const policyType = 0; // CropInsurance
    const policyPremium = ethers.parseEther("1");

    await cropInsuranceProgram.connect(admin).registerNewInsurancePolicy(
      referenceNumber,
      startDate,
      stopDate,
      policyType,
      policyPremium
    );
    await cropInsuranceProgram.connect(admin).activateInsurancePolicy(referenceNumber);

    await cropInsuranceProgram.connect(farmer).depositFunds({ value: policyPremium });
	const farmerData = await cropInsuranceProgram.getFarmerData(
      farmer.address
    );
    const insurancePolicyData = await cropInsuranceProgram.getInsurancePolicyData();

    expect(farmerData.insured).to.be.true;
    expect(insurancePolicyData.totalPolicyPremiumCollected).to.equal(policyPremium);
    expect(await cropInsuranceProgram.balances(farmer.address)).to.equal(policyPremium);
  });
});
