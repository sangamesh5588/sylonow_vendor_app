# Screen Logic

in \_buildScreenItem Widget add 2 button

1. Create Package
2. Manage Time Slots

A.1 : Create Package
when user tap on Create package it should redirect to a new screen where we show vendor 3 by 3 grid , container with 8px border radius and with below small Add button when vendor add some add-ons then it should show the calculate amount and show at the bottom of the screen and above to the Create Package button this package button should be place in scaffolds bottom property, also give vendor option to edit the package total price this price should be restricted means if total is 400 then it can not increase this price it only can reduce this price.

After that vendor tap on create package button that store this package in `supabase table screen_packages` this table is not exists right now so create it and add the necessary field like screen_id , package_name , package_price , package_description , package_image and package_addons

A.2 : Manage Time Slots
When its tapped it should navigate to `time_slots_managment_screen.dart`
