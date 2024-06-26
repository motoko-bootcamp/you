export const idlFactory = ({ IDL }) => {
  const Mood = IDL.Text;
  const UserCanister = IDL.Service({
    'reboot_dailyCheck' : IDL.Func([Mood], [], []),
    'reboot_isAlive' : IDL.Func([], [IDL.Bool], ['query']),
  });
  return UserCanister;
};
export const init = ({ IDL }) => { return []; };
