import Result "mo:base/Result";
module Friend {

    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    public type Friend = {
        name : Text;
        canisterId : Principal;
    };

    public type FriendRequest = {
        id : Nat;
        name : Text;
        sender : Principal;
        message : Text;
    };

    public type FriendRequestError = {
        #AlreadyFriend;
        #AlreadyRequested;
        #NotEnoughCycles;
    };

    public type FriendRequestResult = Result<(), FriendRequestError>;

};
