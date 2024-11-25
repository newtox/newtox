// Initialize variables for token and badge ID
let access_token = '';
let badgeid = 0;

function SetFavoriteFeaturedBadge(access_token, badgeid) {
    return $J.ajax({
        type: 'POST',
        url: `https://api.steampowered.com/IPlayerService/SetFavoriteBadge/v1?access_token=${access_token}`,
        data: {
            badgeid: badgeid
        },
        crossDomain: true,
        xhrFields: {
            withCredentials: false
        }
    })
    .done(function(response) {
        console.log('Badge set successfully');
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
        console.log('Response:', jqXHR.responseText);
    });
}

// First try to use the predefined token
if (access_token) {
    SetFavoriteFeaturedBadge(access_token, badgeid);
}
// Fallback to domain-specific token fetching if needed
else if (window.location.href.includes('steampowered')) {
    const loyaltyStore = $J('[data-loyaltystore]').data('loyaltystore');
    if (loyaltyStore && loyaltyStore.webapi_token) {
        access_token = loyaltyStore.webapi_token;
        SetFavoriteFeaturedBadge(access_token, badgeid);
    }
} else if (window.location.href.includes('steamcommunity')) {
    const profileConfig = $J('#profile_edit_config').attr('data-profile-edit');
    if (profileConfig) {
        const config = JSON.parse(profileConfig);
        access_token = config.webapi_token;
        SetFavoriteFeaturedBadge(access_token, badgeid);
    }
}
