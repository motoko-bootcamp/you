import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Types "types";


shared ({ caller = creator }) actor class RelationshipCanister(humans : [Principal]) = this {

    type Message = Types.Message;
    
    stable var messages : [Message] = [];

    // Function to check if the caller is in the humans list
    func Authorized(caller : Principal) : Bool {
        var human = Array.find<Principal>(humans, func (x : Principal)
        {
            return x == caller;
        });

        switch (human) {
            case (null) { return false; };
            case (_) { return true; };
        };
    };

    public query ({ caller }) func reboot_relationship_getMessages() : async [Message] {
        assert (Authorized(caller));
        return messages;
    };

    public shared ({ caller }) func reboot_relationship_sendMessage(
        message : Text
    ) : async () {
        assert (Authorized(caller));
        messages := Array.append<Message>(messages,
        [{
            sender = caller;
            content = message;
            time = Time.now();
        }]);
    };

};
