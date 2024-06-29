import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Http "http";
import Prim "mo:⛔";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {
    let NANOSECONDS_PER_DAY = 24 * 60 * 60 * 1_000_000_000;

    stable let version : (Nat, Nat, Nat) = (0, 0, 2);
    stable let birth : Time.Time = Time.now();
    stable let owner : Principal = creator;
    stable let name : Name = yourName;

    public type Mood = Text;
    public type Name = Text;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();

    stable var modules : [(Text, Principal)] = [];

    // Function to kill the user if they haven't pinged in 24 hours
    func _kill() : async () {
        let now = Time.now();
        if (now - latestPing > NANOSECONDS_PER_DAY) {
            alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    let _daily = Timer.recurringTimer<system>(#nanoseconds(NANOSECONDS_PER_DAY), _kill);

    public query func reboot_user_isAlive() : async Bool {
        return alive;
    };

    // Import the board actor and related types
    public type WriteError = {
        #NotEnoughCycles;
        #MemoryFull;
        #NameTooLong;
        #MoodTooLong;
        #NotAllowed;
    };

    public type MessageError = {
        #NotEnoughCycles;
        #MemoryFull;
        #MessageTooLong;
        #NotAllowed;
    };

    let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
        reboot_board_write : (name : Name, mood : Mood) -> async Result<(), WriteError>;
    };

    public shared ({ caller }) func reboot_user_dailyCheck(
        mood : Mood
    ) : async Result<(), WriteError> {
        assert (caller == owner);
        alive := true;
        latestPing := Time.now();

        // Write the daily check to the board
        try {
            Cycles.add<system>(1_000_000_000);
            await board.reboot_board_write(name, mood);
        } catch (e) {
            throw e;
        };
    };

//-----------------------END BASE-------------------
//-----------------------Contacts--------------------

    public query ({caller}) func reboot_getName() : async Name {
        assert (caller == owner);
        return name;
    };

    public query ({caller}) func reboot_getOwner() : async Principal {
        assert (caller == owner);
        return owner;
    };

    public query ({caller}) func reboot_getBirth() : async Int {
        assert (caller == owner);
        return birth;
    };

    public query ({caller}) func reboot_getAge() : async Int {
        assert (caller == owner);
        return Time.now() - birth;
    };


    public shared query func reboot_user_getModules () : async [(Text, Principal)] {
        return modules;
    };

    public type HttpRequest = Http.Request;
    public type HttpResponse = Http.Response;
    public shared func http_request(_request : HttpRequest) : async HttpResponse {

        // let friendRequests = await reboot_contacts_getFriendRequests();
        // let friends = await reboot_contacts_getFriends();

        return ({
            body = Text.encodeUtf8(
                "You\n"
                # "---\n"
                # "Name: " # name # "\n"
                # "Owner: " # Principal.toText(owner) # "\n"
                # "Birth: " # Int.toText(birth) # "\n"
                # "Alive: " # Bool.toText(alive) # "\n"
                // # "Friends: " # Nat.toText(friends.size()) # "\n"
                // # "Pending requests: " # Nat.toText(friendRequests.size()) # "\n"
                // # "Pending messages: " # Nat.toText(messages.size()) # "\n"
                # "Version: " # Nat.toText(version.0) # "." # Nat.toText(version.1) # "." # Nat.toText(version.2) # "\n"
                # "Cycle Balance: " # Nat.toText(Cycles.balance()) # " cycles " # "(" # Nat.toText(Cycles.balance() / 1_000_000_000_000) # " T" # ")\n"
                # "Heap size (current): " # Nat.toText(Prim.rts_heap_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_heap_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Heap size (max): " # Nat.toText(Prim.rts_max_live_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_max_live_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Memory size: " # Nat.toText(Prim.rts_memory_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_memory_size() / (1024 * 1024))) # " Mb" # ")\n"
            );
            headers = [("Content-Type", "text/plain")];
            status_code = 200;
        });
    };
    
//-----------------------END Contacts----------------


//-----------------------Admin----------------------

    public query func reboot_user_version() : async (Nat, Nat, Nat) {
        return version;
    };

};
