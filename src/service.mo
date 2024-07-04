import Result "mo:base/Result";

module{

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

    public type FriendRequestError = {
        #AlreadyFriend;
        #AlreadyRequested;
        #NotEnoughCycles;
    };

    public type FriendRequestResult = Result.Result<(), FriendRequestError>;

}