const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

// In-memory storage (replace with database in production)
let studyGroups = [
    {
        id: '1',
        name: 'Advanced Algorithms Study Group',
        courseId: 'cs101',
        courseName: 'Computer Science 101',
        description: 'Preparing for final exam together',
        memberIds: ['user1', 'user2', 'user3'],
        memberNames: ['Alice', 'Bob', 'Charlie'],
        createdBy: 'user1',
        createdAt: new Date().toISOString(),
        maxMembers: 10,
    },
];

// Get all study groups (my groups + available)
router.get('/', auth, async (req, res) => {
    try {
        const userId = req.user.userId;

        // My groups (where I'm a member)
        const myGroups = studyGroups.filter(g => g.memberIds.includes(userId));

        // Available groups (where I'm not a member and not full)
        const availableGroups = studyGroups.filter(g =>
            !g.memberIds.includes(userId) && g.memberIds.length < g.maxMembers
        );

        res.json({
            myGroups,
            available: availableGroups,
        });
    } catch (error) {
        console.error('Get study groups error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Create a new study group
router.post('/', auth, async (req, res) => {
    try {
        const { name, courseId, courseName, description, maxMembers } = req.body;
        const userId = req.user.userId;
        const userName = req.user.name;

        if (!name || !courseId || !courseName) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const newGroup = {
            id: `group_${Date.now()}`,
            name,
            courseId,
            courseName,
            description: description || '',
            memberIds: [userId],
            memberNames: [userName],
            createdBy: userId,
            createdAt: new Date().toISOString(),
            maxMembers: maxMembers || 10,
        };

        studyGroups.push(newGroup);

        res.status(201).json(newGroup);
    } catch (error) {
        console.error('Create study group error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Join a study group
router.post('/:groupId/join', auth, async (req, res) => {
    try {
        const { groupId } = req.params;
        const userId = req.user.userId;
        const userName = req.user.name;

        const group = studyGroups.find(g => g.id === groupId);

        if (!group) {
            return res.status(404).json({ error: 'Group not found' });
        }

        if (group.memberIds.includes(userId)) {
            return res.status(400).json({ error: 'Already a member' });
        }

        if (group.memberIds.length >= group.maxMembers) {
            return res.status(400).json({ error: 'Group is full' });
        }

        group.memberIds.push(userId);
        group.memberNames.push(userName);

        res.json(group);
    } catch (error) {
        console.error('Join study group error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Leave a study group
router.post('/:groupId/leave', auth, async (req, res) => {
    try {
        const { groupId } = req.params;
        const userId = req.user.userId;

        const group = studyGroups.find(g => g.id === groupId);

        if (!group) {
            return res.status(404).json({ error: 'Group not found' });
        }

        const memberIndex = group.memberIds.indexOf(userId);

        if (memberIndex === -1) {
            return res.status(400).json({ error: 'Not a member' });
        }

        group.memberIds.splice(memberIndex, 1);
        group.memberNames.splice(memberIndex, 1);

        // Delete group if no members left
        if (group.memberIds.length === 0) {
            studyGroups = studyGroups.filter(g => g.id !== groupId);
        }

        res.json({ message: 'Left group successfully' });
    } catch (error) {
        console.error('Leave study group error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get group details
router.get('/:groupId', auth, async (req, res) => {
    try {
        const { groupId } = req.params;

        const group = studyGroups.find(g => g.id === groupId);

        if (!group) {
            return res.status(404).json({ error: 'Group not found' });
        }

        res.json(group);
    } catch (error) {
        console.error('Get group details error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Delete a study group (only creator)
router.delete('/:groupId', auth, async (req, res) => {
    try {
        const { groupId } = req.params;
        const userId = req.user.userId;

        const group = studyGroups.find(g => g.id === groupId);

        if (!group) {
            return res.status(404).json({ error: 'Group not found' });
        }

        if (group.createdBy !== userId) {
            return res.status(403).json({ error: 'Only creator can delete group' });
        }

        studyGroups = studyGroups.filter(g => g.id !== groupId);

        res.json({ message: 'Group deleted successfully' });
    } catch (error) {
        console.error('Delete study group error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
