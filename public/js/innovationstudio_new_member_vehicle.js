const unl_association = document.getElementById('unl-association');
const unl_association_yes = document.getElementById('unl-asso-yes');
const unl_association_no = document.getElementById('unl-asso-no');

const unl_permit = document.getElementById('unl-permit');
const unl_permit_yes = document.getElementById('unl-permit-yes');
const unl_permit_no = document.getElementById('unl-permit-no');

const unl_perimeter = document.getElementById('unl-perimeter');
const unl_perimeter_yes = document.getElementById('unl-perim-yes');
const unl_perimeter_no = document.getElementById('unl-perim-no');

const unl_garage = document.getElementById('unl-garage');
const unl_garage_yes = document.getElementById('unl-garage-yes');
const unl_garage_no = document.getElementById('unl-garage-no');

const parking_checkbox = document.getElementById('parking-checkbox');
const vehicle_info = document.getElementById('vehicle-info');

//     _                   _      _   _
//    /_\   ______ ___  __(_)__ _| |_(_)___ _ _
//   / _ \ (_-<_-</ _ \/ _| / _` |  _| / _ \ ' \
//  /_/ \_\/__/__/\___/\__|_\__,_|\__|_\___/_||_|
// If yes then we don't know enough info
unl_association_yes.addEventListener('input', (e) => {
    unl_permit.classList.remove('dcf-d-none'); // Show this
    unl_permit_yes.checked = false;
    unl_permit_no.checked = false;

    unl_perimeter.classList.add('dcf-d-none');
    unl_perimeter_yes.checked = false;
    unl_perimeter_no.checked = false;

    unl_garage.classList.add('dcf-d-none');
    unl_garage_yes.checked = false;
    unl_garage_no.checked = false;

    vehicle_info.classList.add('dcf-d-none');
    parking_checkbox.classList.add('dcf-d-none');
});

// If no then they would not have a parking permit
unl_association_no.addEventListener('input', (e) => {
    unl_permit.classList.add('dcf-d-none');
    unl_permit_yes.checked = false;
    unl_permit_no.checked = false;

    unl_perimeter.classList.add('dcf-d-none');
    unl_perimeter_yes.checked = false;
    unl_perimeter_no.checked = false;

    unl_garage.classList.add('dcf-d-none');
    unl_garage_yes.checked = false;
    unl_garage_no.checked = false;

    vehicle_info.classList.remove('dcf-d-none'); // Show this
    parking_checkbox.classList.add('dcf-d-none');
});

//   ___               _ _
//  | _ \___ _ _ _ __ (_) |_
//  |  _/ -_) '_| '  \| |  _|
//  |_| \___|_| |_|_|_|_|\__|
// If yes then we don't know enough info
unl_permit_yes.addEventListener('input', (e) => {
    unl_perimeter.classList.remove('dcf-d-none'); // Show this
    unl_perimeter_yes.checked = false;
    unl_perimeter_no.checked = false;

    unl_garage.classList.add('dcf-d-none');
    unl_garage_yes.checked = false;
    unl_garage_no.checked = false;

    vehicle_info.classList.add('dcf-d-none');
    parking_checkbox.classList.add('dcf-d-none');
});

// If no then they don't have a parking permit
unl_permit_no.addEventListener('input', (e) => {
    unl_perimeter.classList.add('dcf-d-none');
    unl_perimeter_yes.checked = false;
    unl_perimeter_no.checked = false;

    unl_garage.classList.add('dcf-d-none');
    unl_garage_yes.checked = false;
    unl_garage_no.checked = false;

    vehicle_info.classList.remove('dcf-d-none'); // Show this
    parking_checkbox.classList.add('dcf-d-none');
});

//   ___         _           _
//  | _ \___ _ _(_)_ __  ___| |_ ___ _ _
//  |  _/ -_) '_| | '  \/ -_)  _/ -_) '_|
//  |_| \___|_| |_|_|_|_\___|\__\___|_|
// If yes then they do not qualify for reciprocal parking
unl_perimeter_yes.addEventListener('input', () => {
    unl_garage.classList.add('dcf-d-none');
    unl_garage_yes.checked = false;
    unl_garage_no.checked = false;

    vehicle_info.classList.remove('dcf-d-none'); // Show this
    parking_checkbox.classList.add('dcf-d-none');
});

// If no then we don't have enough info yet
unl_perimeter_no.addEventListener('input', () => {
    unl_garage.classList.remove('dcf-d-none'); // Show this
    unl_garage_yes.checked = false;
    unl_garage_no.checked = false;

    vehicle_info.classList.add('dcf-d-none');
    parking_checkbox.classList.add('dcf-d-none');
});

//    ___
//   / __|__ _ _ _ __ _ __ _ ___
//  | (_ / _` | '_/ _` / _` / -_)
//   \___\__,_|_| \__,_\__, \___|
//                     |___/
// If yes then they do qualify for reciprocal parking
unl_garage_yes.addEventListener('input', () => {
    vehicle_info.classList.add('dcf-d-none');
    parking_checkbox.classList.remove('dcf-d-none'); // Show this
});

// This is a last catch for incorrect entries and not understanding the questions being asked
unl_garage_no.addEventListener('input', () => {
    vehicle_info.classList.remove('dcf-d-none'); // Show this
    parking_checkbox.classList.add('dcf-d-none');
});
