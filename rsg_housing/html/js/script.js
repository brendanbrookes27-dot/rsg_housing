let currentProperty = null;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
});

// Setup event listeners
function setupEventListeners() {
    // Close button
    document.getElementById('close-btn').addEventListener('click', closeUI);
    
    // Action buttons
    document.getElementById('purchase-btn').addEventListener('click', purchaseProperty);
    document.getElementById('rent-btn').addEventListener('click', rentProperty);
    document.getElementById('enter-btn').addEventListener('click', enterProperty);
    document.getElementById('manage-btn').addEventListener('click', manageProperty);
    document.getElementById('collect-earnings-btn').addEventListener('click', collectEarnings);
    document.getElementById('manage-staff-btn').addEventListener('click', manageStaff);
    
    // ESC key to close
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeUI();
        }
    });
}

// Listen for messages from client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openPropertyUI':
            openPropertyUI(data.property);
            break;
        case 'closePropertyUI':
            closeUI();
            break;
        case 'updateProperty':
            updatePropertyInfo(data.property);
            break;
        case 'updateSaloonEarnings':
            updateSaloonEarnings(data.earnings);
            break;
    }
});

// Open property UI
function openPropertyUI(property) {
    currentProperty = property;
    updatePropertyInfo(property);
    updateActionButtons(property);
    
    document.getElementById('housing-container').classList.remove('hidden');
}

// Close UI
function closeUI() {
    document.getElementById('housing-container').classList.add('hidden');
    currentProperty = null;
    
    // Notify client
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Update property information
function updatePropertyInfo(property) {
    document.getElementById('property-name').textContent = property.label || '-';
    document.getElementById('property-type').textContent = property.type || '-';
    document.getElementById('property-price').textContent = property.price ? `$${property.price}` : '-';
    document.getElementById('property-owner').textContent = property.owner_name || 'Available';
    
    // Update title
    document.getElementById('housing-title').textContent = property.label || 'Property Management';
    
    // Show/hide saloon management
    const saloonSection = document.getElementById('saloon-management');
    if (property.type === 'saloon' && property.owner) {
        saloonSection.classList.remove('hidden');
        loadSaloonEarnings(property.id);
    } else {
        saloonSection.classList.add('hidden');
    }
}

// Update action buttons based on property status
function updateActionButtons(property) {
    const purchaseBtn = document.getElementById('purchase-btn');
    const rentBtn = document.getElementById('rent-btn');
    const enterBtn = document.getElementById('enter-btn');
    const manageBtn = document.getElementById('manage-btn');
    
    // Hide all buttons first
    [purchaseBtn, rentBtn, enterBtn, manageBtn].forEach(btn => {
        btn.style.display = 'none';
    });
    
    if (property.owner) {
        // Property is owned
        if (property.isOwner) {
            // Player owns this property
            enterBtn.style.display = 'block';
            manageBtn.style.display = 'block';
        } else {
            // Someone else owns it - could add doorbell functionality
        }
    } else {
        // Property is available
        purchaseBtn.style.display = 'block';
        if (property.rent > 0) {
            rentBtn.style.display = 'block';
        }
    }
}

// Load saloon earnings
function loadSaloonEarnings(propertyId) {
    fetch(`https://${GetParentResourceName()}/getSaloonEarnings`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: propertyId })
    });
}

// Update saloon earnings display
function updateSaloonEarnings(earnings) {
    document.getElementById('daily-earnings').textContent = `$${earnings.avg_daily_earnings || 0}`;
    document.getElementById('total-earnings').textContent = `$${earnings.total_earnings || 0}`;
    document.getElementById('uncollected-earnings').textContent = `$${earnings.uncollected_earnings || 0}`;
}

// Action button handlers
function purchaseProperty() {
    if (!currentProperty) return;
    
    fetch(`https://${GetParentResourceName()}/purchaseProperty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: currentProperty.id })
    });
    
    closeUI();
}

function rentProperty() {
    if (!currentProperty) return;
    
    fetch(`https://${GetParentResourceName()}/rentProperty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: currentProperty.id })
    });
    
    closeUI();
}

function enterProperty() {
    if (!currentProperty) return;
    
    fetch(`https://${GetParentResourceName()}/enterProperty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: currentProperty.id })
    });
    
    closeUI();
}

function manageProperty() {
    if (!currentProperty) return;
    
    fetch(`https://${GetParentResourceName()}/manageProperty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: currentProperty.id })
    });
    
    closeUI();
}

function collectEarnings() {
    if (!currentProperty) return;
    
    fetch(`https://${GetParentResourceName()}/collectEarnings`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: currentProperty.id })
    });
}

function manageStaff() {
    if (!currentProperty) return;
    
    fetch(`https://${GetParentResourceName()}/manageStaff`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ propertyId: currentProperty.id })
    });
    
    closeUI();
}

// Utility function to get parent resource name
function GetParentResourceName() {
    return window.location.hostname;
}