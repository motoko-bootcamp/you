import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Friends "friends";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Http "http";
import Prim "mo:⛔";
import You "you";
import D "mo:base/Debug";
import Service "service";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {
    let NANOSECONDS_PER_DAY = 24 * 60 * 60 * 1_000_000_000;

    stable let version : (Nat, Nat, Nat) = (0, 0, 2);
    stable let birth : Time.Time = Time.now();
    stable let owner : Principal = creator;
    stable let name : Name = yourName;

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();

    stable var friendRequestId : Nat = 0;


    stable var friends : [Friends.Friend] = [];

    stable var messagesId : Nat = 0;


    public type Mood = You.Mood;
    public type Name = You.Name;
    public type Friend = You.Friend;
    public type FriendRequest = You.FriendRequest;

    public type FriendRequestResult = Friends.FriendRequestResult;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    stable let youState = You.init(#v0_0_0(#data),#v0_1_0(#id), ?{
      name = yourName;
    }, creator);

    var you_ : ?You.You = null;

    private func you() : You.You {
        switch (you_) {
            case (?you) { return you; };
            case (null) {
                let you = You.You(?youState, Principal.fromActor(this), ());
                you_ := ?you;
                
                return you;
            };
        };
    };

    public query func reboot_user_isAlive() : async Bool {
        let ?youClass = you_ else D.trap("init needed");
        return youClass.state.alive;
    };

    public shared(msg) func _init() : async() {
      switch (you_) {
        case (?you) { return; };
        case (null) {
          ignore you();
          you().initTimer<system>();
        };
      };
    };

    func callInit() : async () {
      let myActor : actor{
        _init : () -> async ();
      } = actor(Principal.toText(Principal.fromActor(this)));  
      await myActor._init();
    };

    ignore Timer.setTimer<system>(#nanoseconds(0), callInit);

    // Import the board actor and related types
    public type WriteError = Service.WriteError;

    public type MessageError = Service.MessageError;

    

    public shared ({ caller }) func reboot_user_dailyCheck(
        mood : Mood
    ) : async Result<(), WriteError> {
        return await* you().reboot_user_dailyCheck<system>(caller, mood);
    };

    public shared ({ caller }) func reboot_user_receiveFriendRequest(
        name : Text,
        message : Text,
    ) : async FriendRequestResult {
        return await* you().reboot_user_receiveFriendRequest<system>(caller, name, message);
    };

    public shared ({ caller }) func reboot_user_sendFriendRequest(
        receiver : Principal,
        message : Text,
    ) : async FriendRequestResult {
        return await* you().reboot_user_sendFriendRequest<system>(caller, receiver, message);
    };

    public shared query ({ caller }) func reboot_user_getFriendRequests() : async [FriendRequest] {
        assert (caller == you().state.owner);
        return you().state.friendRequests;
    };

    public shared ({ caller }) func reboot_user_handleFriendRequest(
        id : Nat,
        accept : Bool,
    ) : async Result<(), Text> {
         return await* you().reboot_user_handleFriendRequest<system>(caller, id, accept);
    };

    public shared ({ caller }) func reboot_user_getFriends() : async [Friend] {
        assert (caller == you().state.owner);
        return you().state.friends;
    };

    public shared ({ caller }) func reboot_user_removeFriend(
        canisterId : Principal
    ) : async Result<(), Text> {
        return await* you().reboot_user_removeFriend<system>(caller, canisterId);
    };

    public shared ({ caller }) func reboot_user_sendMessage(
        receiver : Principal,
        message : Text,
    ) : async Result<(), MessageError> {
        return await* you().reboot_user_sendMessage<system>(caller, receiver, message);
    };

    public shared ({ caller }) func reboot_user_receiveMessage(
        message : Text
    ) : async Result<(), MessageError> {
        return await* you().reboot_user_receiveMessage<system>(caller, message);
    };

    public shared ({ caller }) func reboot_user_readMessages() : async [(Nat, Name, Text)] {
        assert (caller == you().state.owner);
        return you().state.messages;
    };

    public shared ({ caller }) func reboot_user_clearMessage(
        id : Nat
    ) : async Result<(), Text> {
        return await* you().reboot_user_clearMessage<system>(caller, id);
    };

    public shared ({ caller }) func reboot_user_clearAllMessages() : async Result<(), Text> {
        return await* you().reboot_user_clearAllMessages<system>(caller);
    };

    public query func reboot_user_version() : async (Nat, Nat, Nat) {
        return you().state.version;
    };

    public type HttpRequest = Http.Request;
    public type HttpResponse = Http.Response;
    public query func http_request(_request : HttpRequest) : async HttpResponse {
        return ({
            body = Text.encodeUtf8(
                "You\n"
                # "---\n"
                # "Name: " # you().state.name # "\n"
                # "Owner: " # Principal.toText(you().state.owner) # "\n"
                # "Birth: " # Int.toText(you().state.birth) # "\n"
                # "Alive: " # Bool.toText(you().state.alive) # "\n"
                # "Friends: " # Nat.toText(you().state.friends.size()) # "\n"
                # "Pending requests: " # Nat.toText(you().state.friendRequests.size()) # "\n"
                # "Pending messages: " # Nat.toText(you().state.messages.size()) # "\n"
                # "Version: " # Nat.toText(you().state.version.0) # "." # Nat.toText(you().state.version.1) # "." # Nat.toText(you().state.version.2) # "\n"
                # "Cycle Balance: " # Nat.toText(Cycles.balance()) # " cycles " # "(" # Nat.toText(Cycles.balance() / 1_000_000_000_000) # " T" # ")\n"
                # "Heap size (current): " # Nat.toText(Prim.rts_heap_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_heap_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Heap size (max): " # Nat.toText(Prim.rts_max_live_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_max_live_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Memory size: " # Nat.toText(Prim.rts_memory_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_memory_size() / (1024 * 1024))) # " Mb" # ")\n"
            );
            headers = [("Content-Type", "text/plain")];
            status_code = 200;
        });
    };

    system func postupgrade() {
        you().state := {
            version = (0, 0, 2);
            birth = birth;
            owner = owner;
            var alive = alive;
            var name = yourName;
            var mood = "not set";
            var latestPing = latestPing;
            var friendRequestId = friendRequestId;
            var friendRequests = [];
            var friends = friends;
            var messages = [];
            var messagesId = messagesId;
        };

    };

};
