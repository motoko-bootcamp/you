import MigrationTypes "../types";
import Time "mo:base/Time";
import v0_1_0 "types";
import D "mo:base/Debug";

module {
  public func upgrade(prevmigration_state: MigrationTypes.State, args: MigrationTypes.Args, caller: Principal): MigrationTypes.State {

    let (name) = switch (args) {
      case (?args) {(args.name)};
      case (_) {("nobody")};
    };

    let state : v0_1_0.State = {
      version = (0,2,0);
      birth = Time.now();
      owner = caller;
      var name = name;
      var alive = true;
      var mood = "not set";
      var latestPing = Time.now();
      var friendRequestId = 0;
      var friendRequests = [];
      var friends = [];
      var messagesId = 0;
      var messages = [];
    };

    return #v0_1_0(#data(state));
  };
};