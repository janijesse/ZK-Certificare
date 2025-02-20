%lang starknet
#[starknet::interface]

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address

struct Certificate {
    institution_id: felt,
    student_id: felt,
    certificate_hash: felt,
    issue_date: felt,
}

struct ZKProof {
    certificate_id: felt,
    proof_data: felt,
    is_valid: felt,
}

@storage_var
func certificates(certificate_id: felt) -> (certificate: Certificate) {
}

@storage_var
func proofs(proof_id: felt) -> (proof: ZKProof) {
}

@storage_var
func institution_registry(address: felt) -> (is_registered: felt) {
}

@storage_var
func owner() -> (address: felt) {
}

@event
func CertificateIssued(certificate_id: felt, student_id: felt) {
}

@event
func ProofGenerated(proof_id: felt, certificate_id: felt) {
}

@constructor
func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(admin_address: felt) {
    owner.write(admin_address);
    return ();
}

@external
func register_institution{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(institution_address: felt) {
    let (current_owner) = owner.read();
    let (caller) = get_caller_address();
    assert caller = current_owner;
    
    institution_registry.write(institution_address, 1);
    return ();
}

@external
func issue_certificate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    certificate_id: felt,
    student_id: felt,
    certificate_hash: felt,
    issue_date: felt
) {
    let (caller) = get_caller_address();
    let (is_registered) = institution_registry.read(caller);
    assert is_registered = 1;
    
    let certificate = Certificate(
        institution_id=caller,
        student_id=student_id,
        certificate_hash=certificate_hash,
        issue_date=issue_date
    );
    
    certificates.write(certificate_id, certificate);
    
    CertificateIssued.emit(certificate_id, student_id);
    
    return ();
}

@external
func generate_proof{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    proof_id: felt,
    certificate_id: felt,
    proof_data: felt
) {
    let (certificate) = certificates.read(certificate_id);
    assert certificate.certificate_hash != 0;
    
    let proof = ZKProof(
        certificate_id=certificate_id,
        proof_data=proof_data,
        is_valid=1
    );
    
    proofs.write(proof_id, proof);
    
    ProofGenerated.emit(proof_id, certificate_id);
    
    return ();
}

@external
func verify_certificate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(
    proof_id: felt, 
    check_value: felt
) -> (result: felt) {
    let (proof) = proofs.read(proof_id);
    assert proof.proof_data != 0;
    
    let verification_result = simple_verify(proof.proof_data, check_value);
    
    return (verification_result);
}

@view
func get_certificate{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(certificate_id: felt) -> (certificate: Certificate) {
    let (certificate) = certificates.read(certificate_id);
    return (certificate,);
}

@view
func get_proof{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
}(proof_id: felt) -> (proof: ZKProof) {
    let (proof) = proofs.read(proof_id);
    return (proof,);
}

func simple_verify(
    proof_data: felt,
    input: felt
) -> (result: felt) {
    if (proof_data == input) {
        return (1,);
    } else {
        return (0,);
    }
}