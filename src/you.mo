import MigrationTypes "migrations/types";
import Migration "migrations";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Result "mo:base/Result";
import Service "service";
import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";

module {

  public type State = MigrationTypes.State;

  public type CurrentState = MigrationTypes.Current.State;

  public type Environment = MigrationTypes.Current.Environment;

  public type Name = MigrationTypes.Current.Name;
  public type Mood = MigrationTypes.Current.Mood;
  public type Friend = MigrationTypes.Current.Friend;
  public type FriendRequest = MigrationTypes.Current.FriendRequest;

  public func initialState() : State {#v0_0_0(#data)};
  public let currentStateVersion = #v0_1_0(#id);

  public let NANOSECONDS_PER_DAY = 86400000000000;

  let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
      reboot_board_write : (name : Name, mood : Mood) -> async Result.Result<(), Service.WriteError>;
  };

  public let init = Migration.migrate;




  public class You(stored: ?State, canister: Principal, environment: Environment){

    /// Initializes the ledger state with either a new state or a given state for migration. 
    /// This setup process involves internal data migration routines.
    public var state : CurrentState = switch(stored){
      case(null) {
        let #v0_1_0(#data(foundState)) = Migration.migrate(initialState(), currentStateVersion, null, canister);
        foundState;
      };
      case(?val) {
        let #v0_1_0(#data(foundState)) = Migration.migrate(val, currentStateVersion, null, canister);
        foundState;
      };
    };

    // Function to kill the user if they haven't pinged in 24 hours
    private func _kill() : async () {
        let now = Time.now();
        if (now - state.latestPing > NANOSECONDS_PER_DAY) {
            state.alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    public func initTimer<system>(){
      let _daily = Timer.recurringTimer<system>(#nanoseconds(NANOSECONDS_PER_DAY), _kill);
    };

    public func reboot_user_dailyCheck<system>(caller: Principal,
        mood : Mood
    ) : async* Result.Result<(), Service.WriteError> {
        assert (caller == state.owner);
        state.alive := true;
        state.latestPing := Time.now();
        state.mood := mood;

        // Write the daily check to the board
        try {
            Cycles.add<system>(1_000_000_000);
            await board.reboot_board_write(state.name, mood);
        } catch (e) {
            throw e;
        };
    };

    public func reboot_user_receiveFriendRequest<system>(
      caller: Principal,
        name : Text,
        message : Text,
    ) : async* Service.FriendRequestResult {
        // Check if there is enough cycles attached (Fee for Friend Request) and accept them
        let availableCycles = Cycles.available();
        let acceptedCycles = Cycles.accept<system>(availableCycles);
        if (acceptedCycles < 1_000_000_000) {
            return #err(#NotEnoughCycles);
        };

        let request : FriendRequest = {
            id = state.friendRequestId;
            name = name;
            sender = caller;
            message = message;
        };

        // Check if the user is already a friend
        for (friend in state.friends.vals()) {
            if (friend.canisterId == caller) {
                return #err(#AlreadyFriend);
            };
        };

        // Check if the user has already sent a friend request
        for (request in state.friendRequests.vals()) {
            if (request.sender == caller) {
                return #err(#AlreadyRequested);
            };
        };

        state.friendRequests := Array.append<FriendRequest>(state.friendRequests, [request]);
        state.friendRequestId += 1;
        return #ok();
    };

    public func reboot_user_sendFriendRequest(caller: Principal,
        receiver : Principal,
        message : Text,
    ) : async* Service.FriendRequestResult {
        assert (caller == state.owner);
        // Create the actor reference
        let friendActor = actor (Principal.toText(receiver)) : actor {
            reboot_user_receiveFriendRequest : (name : Text, message : Text) -> async Service.FriendRequestResult;
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            return await friendActor.reboot_user_receiveFriendRequest(state.name, message);
        } catch (e) {
            throw e;
        };
    };

    public func reboot_user_handleFriendRequest(
      caller: Principal,
        id : Nat,
        accept : Bool,
    ) : async* Result.Result<(), Text> {
        assert (caller == state.owner);
        // Check that the friend request exists
        for (request in state.friendRequests.vals()) {
            if (request.id == id) {
                // If the request is accepted
                if (accept) {
                    // Add the friend to the list
                    state.friends := Array.append<Friend>(state.friends, [{ name = request.name; canisterId = request.sender }]);
                    // Remove the request from the list
                    state.friendRequests := Array.filter<FriendRequest>(state.friendRequests, func(request : FriendRequest) { request.id != id });
                    return #ok();
                } else {
                    // Remove the request from the list
                    state.friendRequests := Array.filter<FriendRequest>(state.friendRequests, func(request : FriendRequest) { request.id != id });
                    return #ok();
                };
            };
        };
        return #err("Friend request not found for id " # Nat.toText(id));
    };

    public func reboot_user_removeFriend(
      caller: Principal,
        canisterId : Principal
    ) : async* Result.Result<(), Text> {
        assert (caller == state.owner);
        for (friend in state.friends.vals()) {
            if (friend.canisterId == canisterId) {
                state.friends := Array.filter<Friend>(state.friends, func(x : Friend) { x.canisterId != canisterId });
                return #ok();
            };
        };
        return #err("Friend not found with canisterId " # Principal.toText(canisterId));
    };

    public func reboot_user_sendMessage(
      caller: Principal,
        receiver : Principal,
        message : Text,
    ) : async* Result.Result<(), Service.MessageError> {
        assert (caller == state.owner);
        // Create the actor reference
        let friendActor = actor (Principal.toText(receiver)) : actor {
            reboot_user_receiveMessage : (message : Text) -> async Result.Result<(), Service.MessageError>;
        };
        // Attach the cycles to the call (1 billion cycles)
        Cycles.add<system>(1_000_000_000);
        // Call the function (handle potential errors)
        try {
            return await friendActor.reboot_user_receiveMessage(message);
        } catch (e) {
            throw e;
        };
    };

    public func reboot_user_receiveMessage(
      caller: Principal,
        message : Text
    ) : async* Result.Result<(), Service.MessageError> {
        // Check if there is enough cycles attached (Fee for Message) and accept them
        let availableCycles = Cycles.available();
        let acceptedCycles = Cycles.accept<system>(availableCycles);
        if (acceptedCycles < 1_000_000_000) {
            return #err(#NotEnoughCycles);
        };
        // Check that the message is not too long
        if (message.size() > 1024) {
            return #err(#MessageTooLong);
        };

        // Check if the caller is already a friend
        for (friend in state.friends.vals()) {
            if (friend.canisterId == caller) {
                state.messages := Array.append<(Nat, Name, Text)>(state.messages, [(state.messagesId, friend.name, message)]);
                state.messagesId += 1;
                return #ok();
            };
        };
        return #err(#NotAllowed);
    };

    public func reboot_user_clearMessage(
      caller: Principal,
        id : Nat
    ) : async* Result.Result<(), Text> {
        assert (caller == state.owner);
        for (message in state.messages.vals()) {
            if (message.0 == id) {
                state.messages := Array.filter<(Nat, Name, Text)>(state.messages, func(x : (Nat, Name, Text)) { x.0 != id });
                return #ok();
            };
        };
        return #err("Message not found with id " # Nat.toText(id));
    };

    public func reboot_user_clearAllMessages(caller: Principal) : async* Result.Result<(), Text> {
        assert (caller == state.owner);
        state.messages := [];
        return #ok();
    };
 

  };
}