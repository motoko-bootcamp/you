import Time "mo:base/Time";
// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead


module {

  public type Name = Text;
  public type Mood = Text;

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

  public type InitArgs ={
    name: Text;
  };
  public type Environment = ();
  public type State = {
    version : (Nat, Nat, Nat);
    birth : Time.Time;
    owner : Principal;
    var name : Name;
    var mood : Mood;
    var alive : Bool;
    var latestPing : Time.Time;
    var friends : [Friend];
    var friendRequestId: Nat;
    var friendRequests : [FriendRequest];
    var messagesId : Nat;
    var messages : [(Nat, Name, Text)]
  };
};