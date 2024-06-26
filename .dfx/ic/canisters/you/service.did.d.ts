import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type Mood = string;
export interface UserCanister {
  'reboot_dailyCheck' : ActorMethod<[Mood], undefined>,
  'reboot_isAlive' : ActorMethod<[], boolean>,
}
export interface _SERVICE extends UserCanister {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
