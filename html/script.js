// RSG Housing UI JavaScript
let currentProperty = null;
let currentPurchaseType = null;
let furniturePlacementMode = false;
let selectedFurnitureCategory = 'chairs';

// Initialize UI
document.addEventListener('DOMContentLoaded', function() {
    // Hide UI initially
    document.getElementById('housing-container').classList.add('hidden');
    
    // Load furniture categories
    loadFurnitureItems();
    
    // Setup event listeners
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    // Close UI on Escape key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeUI();
        }
    });
    
    // Prevent context menu
    document.addEventListener('contextmenu', function(event) {
        event.preventDefault();
    });
}

// Message handler for NUI callbacks
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openUI':
            openUI(data.property);
            break;
        case 'closeUI':
            closeUI();
            break;
        case 'updateProperty':
            updatePropertyInfo(data.property);
            break;
        case 'showNotification':
            showNotification(data.type, data.title, data.message);
            break;
        case 'updateKeyHolders':
            updateKeyHolders(data.keyHolders);
            break;
        case 'updateRoommates':
            updateRoommates(data.roommates);
            break;
        case 'toggleFurnitureMode':
            toggleFurnitureMode();
            break;
        default:
            break;
    }
});

// Open UI
function openUI(property) {
    currentProperty = property;
    updatePropertyInfo(property);
    updateButtonVisibility(property);
    document.getElementById('housing-container').classList.remove('hidden');
    document.getElementById('main-menu').classList.remove('hidden');
}

// Close UI
function closeUI() {
    document.getElementById('housing-container').classList.add('hidden');
    hideAllMenus();
    
    // Send close event to client
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    });
}

// Hide all menus
function hideAllMenus() {
    const menus = ['main-menu', 'purchase-menu', 'keys-menu', 'furniture-menu', 'settings-menu'];
    menus.forEach(menuId => {
        document.getElementById(menuId).classList.add('hidden');
    });
}

// Update property information
function updatePropertyInfo(property) {
    if (!property) return;
    
    document.getElementById('property-name').textContent = property.label;
    document.getElementById('property-type').textContent = `Type: ${property.type}`;
    document.getElementById('property-owner').textContent = property.owner ? `Owner: ${property.owner}` : 'Available';
    document.getElementById('property-price').textContent = `Price: $${property.buy_price.toLocaleString()}`;
    document.getElementById('property-rent').textContent = `Rent: $${property.rent_price}/week`;
    
    // Update property image
    const propertyImage = document.getElementById('property-image');
    if (property.images && property.images.length > 0) {
        propertyImage.src = `images/${property.images[0]}`;
    } else {
        propertyImage.src = 'images/default-property.jpg';
    }
}

// Update button visibility based on property ownership
function updateButtonVisibility(property) {
    const buttons = {
        'enter-property': property.hasKeys,
        'buy-property': !property.owner && property.buy_price > 0,
        'rent-property': !property.owner && property.rent_price > 0,
        'pay-rent': property.isOwner && property.ownership_type === 'rented',
        'manage-keys': property.isOwner,
        'furniture-store': property.hasKeys,
        'property-settings': property.isOwner,
        'sell-property': property.isOwner && property.ownership_type === 'owned'
    };
    
    Object.keys(buttons).forEach(buttonId => {
        const button = document.getElementById(buttonId);
        if (button) {
            button.style.display = buttons[buttonId] ? 'flex' : 'none';
        }
    });
}

// Enter property
function enterProperty() {
    fetch(`https://${GetParentResourceName()}/enterProperty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id
        })
    });
    closeUI();
}

// Show buy menu
function showBuyMenu() {
    currentPurchaseType = 'buy';
    showPurchaseMenu('Buy Property', currentProperty.buy_price, 'This will give you full ownership of the property.');
}

// Show rent menu
function showRentMenu() {
    currentPurchaseType = 'rent';
    showPurchaseMenu('Rent Property', currentProperty.rent_price, 'This will give you rental access to the property.');
}

// Show purchase menu
function showPurchaseMenu(title, price, description) {
    document.getElementById('purchase-title').textContent = title;
    document.getElementById('purchase-property-name').textContent = currentProperty.label;
    document.getElementById('purchase-property-type').textContent = `Type: ${currentProperty.type}`;
    document.getElementById('purchase-type-label').textContent = currentPurchaseType === 'buy' ? 'Purchase Price:' : 'Weekly Rent:';
    document.getElementById('purchase-price').textContent = `$${price.toLocaleString()}`;
    document.getElementById('purchase-description').textContent = description;
    
    hideAllMenus();
    document.getElementById('purchase-menu').classList.remove('hidden');
}

// Hide purchase menu
function hidePurchaseMenu() {
    document.getElementById('purchase-menu').classList.add('hidden');
    document.getElementById('main-menu').classList.remove('hidden');
}

// Confirm purchase
function confirmPurchase() {
    fetch(`https://${GetParentResourceName()}/purchaseProperty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            type: currentPurchaseType
        })
    });
    closeUI();
}

// Pay rent
function payRent() {
    fetch(`https://${GetParentResourceName()}/payRent`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id
        })
    });
    closeUI();
}

// Sell property
function sellProperty() {
    if (confirm('Are you sure you want to sell this property? You will receive 80% of the original purchase price.')) {
        fetch(`https://${GetParentResourceName()}/sellProperty`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                propertyId: currentProperty.id
            })
        });
        closeUI();
    }
}

// Show keys menu
function showKeysMenu() {
    hideAllMenus();
    document.getElementById('keys-menu').classList.remove('hidden');
    loadKeyHolders();
}

// Hide keys menu
function hideKeysMenu() {
    document.getElementById('keys-menu').classList.add('hidden');
    document.getElementById('main-menu').classList.remove('hidden');
}

// Give keys
function giveKeys() {
    const playerId = document.getElementById('player-id-input').value;
    const keyType = document.getElementById('key-type-select').value;
    
    if (!playerId) {
        showNotification('error', 'Error', 'Please enter a valid player ID');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/giveKeys`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            playerId: parseInt(playerId),
            keyType: keyType
        })
    });
    
    document.getElementById('player-id-input').value = '';
}

// Load key holders
function loadKeyHolders() {
    fetch(`https://${GetParentResourceName()}/getKeyHolders`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id
        })
    });
}

// Update key holders list
function updateKeyHolders(keyHolders) {
    const container = document.getElementById('key-holders-list');
    container.innerHTML = '';
    
    if (keyHolders.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #cccccc;">No key holders</p>';
        return;
    }
    
    keyHolders.forEach(holder => {
        const item = document.createElement('div');
        item.className = 'key-holder-item';
        item.innerHTML = `
            <div class="key-holder-info">
                <div class="key-holder-name">${holder.name}</div>
                <div class="key-holder-type">${holder.key_type}</div>
            </div>
            ${holder.key_type !== 'owner' ? `<button class="remove-btn" onclick="removeKeys('${holder.citizenid}')">Remove</button>` : ''}
        `;
        container.appendChild(item);
    });
}

// Remove keys
function removeKeys(citizenid) {
    fetch(`https://${GetParentResourceName()}/removeKeys`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            citizenid: citizenid
        })
    });
}

// Show furniture store
function showFurnitureStore() {
    hideAllMenus();
    document.getElementById('furniture-menu').classList.remove('hidden');
    loadFurnitureItems();
}

// Hide furniture menu
function hideFurnitureMenu() {
    document.getElementById('furniture-menu').classList.add('hidden');
    document.getElementById('main-menu').classList.remove('hidden');
}

// Select furniture category
function selectCategory(category) {
    selectedFurnitureCategory = category;
    
    // Update active category button
    document.querySelectorAll('.category-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-category="${category}"]`).classList.add('active');
    
    loadFurnitureItems();
}

// Load furniture items
function loadFurnitureItems() {
    const container = document.getElementById('furniture-items');
    container.innerHTML = '';
    
    // This would normally come from the config
    const furnitureData = {
        chairs: [
            { id: 'chair_01', label: 'Wooden Chair', price: 25 },
            { id: 'chair_02', label: 'Fancy Chair', price: 50 }
        ],
        tables: [
            { id: 'table_01', label: 'Wooden Table', price: 75 },
            { id: 'table_02', label: 'Round Table', price: 100 }
        ],
        beds: [
            { id: 'bed_01', label: 'Simple Bed', price: 150 },
            { id: 'bed_02', label: 'Double Bed', price: 300 }
        ],
        decorations: [
            { id: 'lamp_01', label: 'Oil Lamp', price: 35 },
            { id: 'painting_01', label: 'Landscape Painting', price: 85 }
        ]
    };
    
    const items = furnitureData[selectedFurnitureCategory] || [];
    
    items.forEach(item => {
        const itemElement = document.createElement('div');
        itemElement.className = 'furniture-item';
        itemElement.innerHTML = `
            <h4>${item.label}</h4>
            <div class="price">$${item.price}</div>
        `;
        itemElement.onclick = () => purchaseFurniture(item);
        container.appendChild(itemElement);
    });
}

// Purchase furniture
function purchaseFurniture(item) {
    fetch(`https://${GetParentResourceName()}/purchaseFurniture`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            furnitureId: item.id,
            price: item.price
        })
    });
}

// Toggle furniture placement mode
function toggleFurnitureMode() {
    furniturePlacementMode = !furniturePlacementMode;
    
    const modeText = document.getElementById('furniture-mode-text');
    modeText.textContent = furniturePlacementMode ? 'Exit Placement Mode' : 'Enter Placement Mode';
    
    fetch(`https://${GetParentResourceName()}/toggleFurnitureMode`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            enabled: furniturePlacementMode
        })
    });
    
    if (furniturePlacementMode) {
        closeUI();
    }
}

// Show settings menu
function showSettingsMenu() {
    hideAllMenus();
    document.getElementById('settings-menu').classList.remove('hidden');
    loadRoommates();
    updateLockStatus();
}

// Hide settings menu
function hideSettingsMenu() {
    document.getElementById('settings-menu').classList.add('hidden');
    document.getElementById('main-menu').classList.remove('hidden');
}

// Toggle lock
function toggleLock() {
    fetch(`https://${GetParentResourceName()}/toggleLock`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id
        })
    });
}

// Update lock status
function updateLockStatus() {
    const lockToggle = document.getElementById('lock-toggle');
    const lockStatus = document.getElementById('lock-status');
    
    if (currentProperty.is_locked) {
        lockToggle.classList.remove('unlocked');
        lockStatus.textContent = 'Locked';
        lockToggle.innerHTML = '<i class="fas fa-lock"></i> <span id="lock-status">Locked</span>';
    } else {
        lockToggle.classList.add('unlocked');
        lockStatus.textContent = 'Unlocked';
        lockToggle.innerHTML = '<i class="fas fa-unlock"></i> <span id="lock-status">Unlocked</span>';
    }
}

// Add roommate
function addRoommate() {
    const playerId = document.getElementById('roommate-id-input').value;
    
    if (!playerId) {
        showNotification('error', 'Error', 'Please enter a valid player ID');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/addRoommate`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            playerId: parseInt(playerId)
        })
    });
    
    document.getElementById('roommate-id-input').value = '';
}

// Load roommates
function loadRoommates() {
    fetch(`https://${GetParentResourceName()}/getRoommates`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id
        })
    });
}

// Update roommates list
function updateRoommates(roommates) {
    const container = document.getElementById('roommates-list');
    container.innerHTML = '';
    
    if (roommates.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #cccccc;">No roommates</p>';
        return;
    }
    
    roommates.forEach(roommate => {
        const item = document.createElement('div');
        item.className = 'roommate-item';
        item.innerHTML = `
            <div class="roommate-info">
                <div class="roommate-name">${roommate.name}</div>
                <div class="roommate-role">Roommate</div>
            </div>
            <button class="remove-btn" onclick="removeRoommate('${roommate.citizenid}')">Remove</button>
        `;
        container.appendChild(item);
    });
}

// Remove roommate
function removeRoommate(citizenid) {
    fetch(`https://${GetParentResourceName()}/removeRoommate`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propertyId: currentProperty.id,
            citizenid: citizenid
        })
    });
}

// Show notification
function showNotification(type, title, message) {
    const container = document.getElementById('notification-container');
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const iconMap = {
        success: 'fas fa-check-circle',
        error: 'fas fa-exclamation-circle',
        warning: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };
    
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="${iconMap[type] || iconMap.info}"></i>
        </div>
        <div class="notification-content">
            <div class="notification-title">${title}</div>
            <div class="notification-message">${message}</div>
        </div>
    `;
    
    container.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

// Get parent resource name
function GetParentResourceName() {
    return window.location.hostname === 'localhost' ? 'rsg_housing' : window.location.hostname.split('.')[0];
}