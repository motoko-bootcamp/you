import Result "mo:base/Result";
import Time "mo:base/Time";
module Contacts {

    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    public type Contact = {
        name : Text;
        canisterId : Principal;
    };

    public type RelationshipRequest = {
        name : Text;
        sender : Principal;
        message : Text;
    };

    public type RelationshipRequestError = {
        #AlreadyExistingRelationship;
        #AlreadyRequested;
        #NotEnoughCycles;
    };

    public type Message = {
        sender : Principal;
        content : Text;
        time : Time.Time;
    };

    public type RelationshipRequestResult = Result<(), RelationshipRequestError>;

};
