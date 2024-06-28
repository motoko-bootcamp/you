import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Types "types";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";

shared ({ caller = creator }) actor class ContactsCanister(
    yourName : Text
) = this {

    public type Result<Ok, Err> = Result.Result<Ok, Err>;
    public type Mood = Text;
    public type Name = Text;
    public type Contact = Types.Contact;
    public type RelationshipRequest = Types.RelationshipRequest;
    public type RelationshipRequestResult = Types.RelationshipRequestResult;
    public type Message = Types.Message;


    // stable var contactRequestId : Nat = 0;
    stable var relationshipRequests : [RelationshipRequest] = [];
    stable var contacts : [Contact] = [];
    let name : Name = yourName;

    let owner : Principal = creator;

    public query func reboot_contacts_supportedStandards() : async [{
        name : Text;
        url : Text;
    }] {
        return ([{
            name = "contacts";
            url = "https://github.com/motoko-bootcamp/reboot/blob/main/standards/contacts.md";
        }]);
    };

    public shared ({ caller }) func reboot_contacts_sendContactRequest(
        receiver : Principal,
        message : Text,
    ) : async RelationshipRequestResult {

        assert (caller == owner);

        // Create the actor reference
        let contactUserActor = actor (Principal.toText(receiver)) : actor {
            reboot_contacts_receiveContactRequest : (name : Text, message : Text, senderPrincipal : Principal) -> async RelationshipRequestResult;
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(500_000_000);

        // Call the function (handle potential errors)
        try {
            return await contactUserActor.reboot_contacts_receiveContactRequest(name, message, caller);
        } catch (e) {
            throw e;
        };
    };

    public shared ({ caller }) func reboot_contacts_receiveContactRequest(
        name : Text,
        message : Text,
        senderPrincipal : Principal
    ) : async RelationshipRequestResult {
        
        //Check if the caller is the User Canister.
        assert(caller == owner);

        let relationshipRequestsBuffer : Buffer.Buffer<RelationshipRequest> = Buffer.fromArray(relationshipRequests);

        // Check if there is enough cycles attached (Fee for Contact Request) and accept them
        let availableCycles = Cycles.available();
        let acceptedCycles = Cycles.accept<system>(availableCycles);
        if (acceptedCycles < 500_000_000) {
            return #err(#NotEnoughCycles);
        };


        let request : RelationshipRequest = {
            name = name;
            sender = senderPrincipal;
            message = message;
        };

        // Check if the user is already a contact
        for (contact in contacts.vals()) {
            if (contact.canisterId == senderPrincipal) {
                return #err(#AlreadyExistingRelationship);
            };
        };

        // Check if the user has already sent a contact request
        for (req in relationshipRequests.vals()) {
            if (req.sender == senderPrincipal) {
                return #err(#AlreadyRequested);
            };
        };

        relationshipRequestsBuffer.add(request);
        relationshipRequests := Buffer.toArray(relationshipRequestsBuffer);
        return #ok();
    };

    public shared query ({ caller }) func reboot_contacts_getContactRequests() : async [RelationshipRequest] {
        assert (caller == owner);
        return relationshipRequests;
    };

    public shared func test () : async () {
        relationshipRequests := [];
    };

    public shared ({ caller }) func reboot_contacts_handleContactRequest(
        index : Nat,
        accept : Bool,
    ) : async Result<(), Text> {

        assert (caller == owner);

        // Check if the index is valid
        if (index >= relationshipRequests.size())
        {
            return #err("Contact request not found for index " # Nat.toText(index));
        };

        
       if (accept) {

            // let contactsBuffer : Buffer.Buffer<Contact> = Buffer.fromArray(contacts);

            //TODO: GENERATE THE RELATIONSHIP, the request to accept is in relationshipRequests[index]



            return #ok();
        };
        relationshipRequests := Array.filter<RelationshipRequest>(relationshipRequests, func(x : RelationshipRequest) { x.sender != relationshipRequests[index].sender });
        return #ok();
    };

    public shared query ({ caller }) func reboot_contacts_getContacts() : async [Contact] {
        assert (caller == owner);
        return contacts;
    };

    public shared ({ caller }) func reboot_contacts_removeContact(
        canisterId : Principal
    ) : async Result<(), Text> {
        assert (caller == owner);

        for (contact in contacts.vals()) {
            if (contact.canisterId == canisterId) {
                contacts := Array.filter<Contact>(contacts, func(x : Contact) { x.canisterId != canisterId });
                return #ok();
            };
        };

        return #err("Contact not found with canisterId " # Principal.toText(canisterId));
    };

    public shared ({ caller }) func reboot_contacts_sendMessage(
        contact_name : Text,
        message : Text,
    ) : async RelationshipRequestResult {

        assert (caller == owner);

        let contact_principal : Principal = switch (Array.find<Contact>(contacts, func(x : Contact) { x.name == contact_name })) {
            case (null) { throw Error.reject("No contact with the name " # contact_name) };
            case (?val) { val.canisterId };
        };

        // Create the actor reference
        let contactUserActor = actor (Principal.toText(contact_principal)) : actor {
            reboot_relationship_sendMessage : (message : Text) -> async ();
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(500_000);

        // Call the function (handle potential errors)
        try {
            await contactUserActor.reboot_relationship_sendMessage(message);
            return #ok();
        } catch (e) {
            throw e;
        };
    };

    public shared ({ caller }) func reboot_contacts_getMessages(
        contact_name : Text,
    ) : async [Message] {

        assert (caller == owner);

        let contact_principal : Principal = switch (Array.find<Contact>(contacts, func(x : Contact) { x.name == contact_name })) {
            case (null) { throw Error.reject("No contact with the name " # contact_name) };
            case (?val) { val.canisterId };
        };

        let contactUserActor = actor (Principal.toText(contact_principal)) : actor {
            reboot_relationship_getMessages : () -> async [Message];
        };

        try {
            return await contactUserActor.reboot_relationship_getMessages();
        } catch (e) {
            throw e;
        };
    };

};
