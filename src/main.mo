import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Http "http";
import IC "ic";
import Prim "mo:⛔";

shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {

    public type Name = Text;
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    stable var modulesUser : [(Text, Text, Principal)] = [];
    stable let versionUser : (Nat, Nat, Nat) = (1, 0, 0);
    stable let nameUser : Name = yourName;
    stable let ownerUser : Principal = creator;

    public query func name() : async Name {
        return nameUser;
    };

    public query func owner() : async Principal {
        return ownerUser;
    };

    public query func version() : async (Nat, Nat, Nat) {
        return versionUser;
    };

    public query func energy() : async Nat {
        return Cycles.balance();
    };

    public query func modules() : async [(Text, Text, Principal)] {
        return modulesUser;
    };

    // This call the registry that contains all the wasm modules and install the ones that the user wants
    // This method requires the user to have enough cycles to pay for the installation
    public func grow(
        name : Text,
        moduleType : Text,
        moduleVersion : (Nat, Nat, Nat),
        args : Blob,
    ) : async Result<(), Text> {

        let registry = actor ("") : actor {
            reboot_registry_get_module : shared (Text, (Nat, Nat, Nat)) -> async Blob;
        };

        let wasm = await registry.reboot_registry_get_module(moduleType, moduleVersion);

        let ic = actor ("aaaaa-aa") : IC.Self;

        // Create a canister
        let canisterId = await ic.create_canister({
            settings = null;
        });
        // Install the WebAssembly module inside the canister
        let _installCode = await ic.install_code({
            canister_id = canisterId.canister_id;
            mode = #install;
            arg = Blob.toArray(args);
            wasm_module = Blob.toArray(wasm);
        });

        // Add the module to the list of modules
        modulesUser := Array.append(modulesUser, [(name, moduleType, canisterId.canister_id)]);
        return #ok();
    };

    func _modulesToText(modulesUser : [(Text, Principal)]) : Text {
        return Array.foldRight<(Text, Principal), Text>(
            modulesUser,
            "Name Principal \n---\n",
            func(moduleUser, acc) {
                return (acc # _moduleToText(moduleUser) # "\n");
            },
        );
    };

    func _moduleToText(moduleUsr : (Text, Principal)) : Text {
        return (moduleUsr.0 # " " # Principal.toText(moduleUsr.1));
    };

    public type HttpRequest = Http.Request;
    public type HttpResponse = Http.Response;
    public query func http_request(_request : HttpRequest) : async HttpResponse {
        return ({
            body = Text.encodeUtf8(
                "You\n"
                # "---\n"
                # "Name: " # nameUser # "\n"
                # "Owner: " # Principal.toText(ownerUser) # "\n"
                # "Version: " # Nat.toText(versionUser.0) # "." # Nat.toText(versionUser.1) # "." # Nat.toText(versionUser.2) # "\n"
                # "Cycle Balance: " # Nat.toText(Cycles.balance()) # " cycles " # "(" # Nat.toText(Cycles.balance() / 1_000_000_000_000) # " T" # ")\n"
                # "Heap size (current): " # Nat.toText(Prim.rts_heap_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_heap_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Heap size (max): " # Nat.toText(Prim.rts_max_live_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_max_live_size() / (1024 * 1024))) # " Mb" # ")\n"
                # "Memory size: " # Nat.toText(Prim.rts_memory_size()) # " bytes " # "(" # Float.toText(Float.fromInt(Prim.rts_memory_size() / (1024 * 1024))) # " Mb" # ")\n"
            );
            headers = [("Content-Type", "text/plain")];
            status_code = 200;
        });
    };

};
