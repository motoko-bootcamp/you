
import TFriends "types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Cycles "mo:base/ExperimentalCycles";


module {

    public type Friend = TFriends.Friend;
    public type FriendRequest = TFriends.FriendRequest;
    public type FriendRequestResult = TFriends.FriendRequestResult;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    public func reboot_user_receiveFriendRequest(
        name : Text,
        message : Text,
        senderPrincipal : Principal,
        friendsCanisterId : Principal
    ) : async FriendRequestResult {

        // Create the actor reference
        let friendsActor = actor (Principal.toText(friendsCanisterId)) : actor {
            reboot_friends_receiveFriendRequest : (name : Text, message : Text, senderPrincipal : Principal) -> async FriendRequestResult;
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        
        // Call the function (handle potential errors)
        try {
            let receiveFriendsRes = await friendsActor.reboot_friends_receiveFriendRequest(name, message, senderPrincipal);
            return receiveFriendsRes;
        } catch (e) {
            throw e;
        };
    };

    public func reboot_user_sendFriendRequest(
        receiver : Principal,
        message : Text,
        friendsCanisterId : Principal
    ) : async FriendRequestResult {
        
        // Create the actor reference
        let friendsActor = actor (Principal.toText(friendsCanisterId)) : actor {
            reboot_friends_sendFriendRequest : (receiver : Principal, message : Text) -> async FriendRequestResult;
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            let sendFriendsRes = await friendsActor.reboot_friends_sendFriendRequest(receiver, message);
            return sendFriendsRes;
        } catch (e) {
            throw e;
        };
    };

    //Composite query has been removed given the necessity to call this function from others non-composite.
    public func reboot_user_getFriendRequests(friendsCanisterId : Principal) : async [FriendRequest] {

        // Create the actor reference
        let friendsActor = actor (Principal.toText(friendsCanisterId)) : actor {
            reboot_friends_getFriendRequests : query () -> async [FriendRequest];
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            return await friendsActor.reboot_friends_getFriendRequests();
        } catch (e) {
            throw e;
        };
    };
    
    public func reboot_user_handleFriendRequest(
        id : Nat,
        accept : Bool,
        friendsCanisterId : Principal
    ) : async Result<(), Text> {

        // Create the actor reference
        let friendsActor = actor (Principal.toText(friendsCanisterId)) : actor {
            reboot_friends_handleFriendRequest : (id : Nat, accept : Bool) -> async Result<(), Text>;
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        
        try {
            let handleFriendRes = await friendsActor.reboot_friends_handleFriendRequest(id, accept);
            return handleFriendRes;
        } catch (e) {
            throw e;
        };
    };
    
    //Composite query has been removed given the necessity to call this function from others non-composite.
    public func reboot_user_getFriends(friendsCanisterId : Principal) : async [Friend] {

        // Create the actor reference
        let friendsActor = actor (Principal.toText(friendsCanisterId)) : actor {
            reboot_friends_getFriends : query () -> async [Friend];
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        
        try {
            return await friendsActor.reboot_friends_getFriends();
        } catch (e) {
            throw e;
        };
    };

    public func reboot_user_removeFriend(
        canisterId : Principal,
        friendsCanisterId : Principal
    ) : async Result<(), Text> {

        // Create the actor reference
        let friendsActor = actor (Principal.toText(friendsCanisterId)) : actor {
            reboot_friends_removeFriend : (canisterId: Principal) -> async Result<(), Text>;
        };

        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);

        try {
            return await friendsActor.reboot_friends_removeFriend(canisterId);
        } catch (e) {
            throw e;
        };
    };
};