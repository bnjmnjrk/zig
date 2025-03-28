const std = @import("std");
const uefi = std.os.uefi;
const Guid = uefi.Guid;
const Event = uefi.Event;
const Handle = uefi.Handle;
const Status = uefi.Status;
const Time = uefi.Time;
const SimpleNetwork = uefi.protocol.SimpleNetwork;
const MacAddress = uefi.MacAddress;
const cc = uefi.cc;

pub const ManagedNetwork = extern struct {
    _get_mode_data: *const fn (*const ManagedNetwork, ?*Config, ?*SimpleNetwork) callconv(cc) Status,
    _configure: *const fn (*const ManagedNetwork, ?*const Config) callconv(cc) Status,
    _mcast_ip_to_mac: *const fn (*const ManagedNetwork, bool, *const anyopaque, *MacAddress) callconv(cc) Status,
    _groups: *const fn (*const ManagedNetwork, bool, ?*const MacAddress) callconv(cc) Status,
    _transmit: *const fn (*const ManagedNetwork, *const CompletionToken) callconv(cc) Status,
    _receive: *const fn (*const ManagedNetwork, *const CompletionToken) callconv(cc) Status,
    _cancel: *const fn (*const ManagedNetwork, ?*const CompletionToken) callconv(cc) Status,
    _poll: *const fn (*const ManagedNetwork) callconv(cc) Status,

    /// Returns the operational parameters for the current MNP child driver.
    /// May also support returning the underlying SNP driver mode data.
    pub fn getModeData(self: *const ManagedNetwork, mnp_config_data: ?*Config, snp_mode_data: ?*SimpleNetwork) Status {
        return self._get_mode_data(self, mnp_config_data, snp_mode_data);
    }

    /// Sets or clears the operational parameters for the MNP child driver.
    pub fn configure(self: *const ManagedNetwork, mnp_config_data: ?*const Config) Status {
        return self._configure(self, mnp_config_data);
    }

    /// Translates an IP multicast address to a hardware (MAC) multicast address.
    /// This function may be unsupported in some MNP implementations.
    pub fn mcastIpToMac(self: *const ManagedNetwork, ipv6flag: bool, ipaddress: *const anyopaque, mac_address: *MacAddress) Status {
        return self._mcast_ip_to_mac(self, ipv6flag, ipaddress, mac_address);
    }

    /// Enables and disables receive filters for multicast address.
    /// This function may be unsupported in some MNP implementations.
    pub fn groups(self: *const ManagedNetwork, join_flag: bool, mac_address: ?*const MacAddress) Status {
        return self._groups(self, join_flag, mac_address);
    }

    /// Places asynchronous outgoing data packets into the transmit queue.
    pub fn transmit(self: *const ManagedNetwork, token: *const CompletionToken) Status {
        return self._transmit(self, token);
    }

    /// Places an asynchronous receiving request into the receiving queue.
    pub fn receive(self: *const ManagedNetwork, token: *const CompletionToken) Status {
        return self._receive(self, token);
    }

    /// Aborts an asynchronous transmit or receive request.
    pub fn cancel(self: *const ManagedNetwork, token: ?*const CompletionToken) Status {
        return self._cancel(self, token);
    }

    /// Polls for incoming data packets and processes outgoing data packets.
    pub fn poll(self: *const ManagedNetwork) Status {
        return self._poll(self);
    }

    pub const guid align(8) = Guid{
        .time_low = 0x7ab33a91,
        .time_mid = 0xace5,
        .time_high_and_version = 0x4326,
        .clock_seq_high_and_reserved = 0xb5,
        .clock_seq_low = 0x72,
        .node = [_]u8{ 0xe7, 0xee, 0x33, 0xd3, 0x9f, 0x16 },
    };

    pub const ServiceBinding = extern struct {
        _create_child: *const fn (*const ServiceBinding, *?Handle) callconv(cc) Status,
        _destroy_child: *const fn (*const ServiceBinding, Handle) callconv(cc) Status,

        pub fn createChild(self: *const ServiceBinding, handle: *?Handle) Status {
            return self._create_child(self, handle);
        }

        pub fn destroyChild(self: *const ServiceBinding, handle: Handle) Status {
            return self._destroy_child(self, handle);
        }

        pub const guid align(8) = Guid{
            .time_low = 0xf36ff770,
            .time_mid = 0xa7e1,
            .time_high_and_version = 0x42cf,
            .clock_seq_high_and_reserved = 0x9e,
            .clock_seq_low = 0xd2,
            .node = [_]u8{ 0x56, 0xf0, 0xf2, 0x71, 0xf4, 0x4c },
        };
    };

    pub const Config = extern struct {
        received_queue_timeout_value: u32,
        transmit_queue_timeout_value: u32,
        protocol_type_filter: u16,
        enable_unicast_receive: bool,
        enable_multicast_receive: bool,
        enable_broadcast_receive: bool,
        enable_promiscuous_receive: bool,
        flush_queues_on_reset: bool,
        enable_receive_timestamps: bool,
        disable_background_polling: bool,
    };

    pub const CompletionToken = extern struct {
        event: Event,
        status: Status,
        packet: extern union {
            rx_data: *ReceiveData,
            tx_data: *TransmitData,
        },
    };

    pub const ReceiveData = extern struct {
        timestamp: Time,
        recycle_event: Event,
        packet_length: u32,
        header_length: u32,
        address_length: u32,
        data_length: u32,
        broadcast_flag: bool,
        multicast_flag: bool,
        promiscuous_flag: bool,
        protocol_type: u16,
        destination_address: [*]u8,
        source_address: [*]u8,
        media_header: [*]u8,
        packet_data: [*]u8,
    };

    pub const TransmitData = extern struct {
        destination_address: ?*MacAddress,
        source_address: ?*MacAddress,
        protocol_type: u16,
        data_length: u32,
        header_length: u16,
        fragment_count: u16,

        pub fn getFragments(self: *TransmitData) []Fragment {
            return @as([*]Fragment, @ptrCast(@alignCast(@as([*]u8, @ptrCast(self)) + @sizeOf(TransmitData))))[0..self.fragment_count];
        }
    };

    pub const Fragment = extern struct {
        fragment_length: u32,
        fragment_buffer: [*]u8,
    };
};
